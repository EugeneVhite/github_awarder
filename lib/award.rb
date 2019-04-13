require 'faraday'
require 'zip'
require 'prawn'

require 'dry/monads/result'
require 'dry/monads/do'

require_relative './fake_conn.rb'

module Award
  include Dry::Monads::Result::Mixin
  include Dry::Monads::Do.for(:fetch_top_contributors)

  def fetch_top_contributors(repo)
    host, repo = yield validate_repo(repo)
    names = yield fetch_contribs(host, repo)

    Success(names)
  end

  def zip_contributors(contributors)
    entries = contributors.map do |contributor|
      {
        name: "#{contributor[:name]}.pdf",
        io: pdf_io(contributor[:name], contributor[:place])
      }
    end

    zip(entries)
  end
  
  def pdf_io(name, place)
    pdf = Prawn::Document.new
    pdf.text "Awards ##{place} to: #{name}"
    pdf.render
  end

  private

  def validate_repo(repo_path)
    match_res =/github.com\/(\w+)\/(\w+)/.match(repo_path)
    
    if match_res
      Success(match_res[1..2])
    else
      Failure(:invalid_repo_path)
    end
  end

  def fetch_contribs(host, repo)
    resp = github_connection.get("/repos/#{host}/#{repo}/contributors")

    case resp.status
    when 200
      names = JSON.parse(resp.body)[0..2].map { |c| c['login'] }
      Success(names)
    when 204
      Success([])
    when 404
      Failure(:repo_not_found)
    end
  rescue Faraday::ConnectionFailed
    Failure(:github_unavailable)
  end

  def zip(entries)
    stringio = Zip::OutputStream.write_buffer do |z_io|
      entries.each do |entry|
        z_io.put_next_entry(entry[:name])
        z_io.write(entry[:io])
      end
    end
    stringio.rewind
    stringio.sysread
  end

  def github_connection
    if ENV['RACK_ENV'] == 'test'
      FakeConn.new
    else
      Faraday.new(url: 'https://api.github.com')
    end
  end
  
  extend self
end
