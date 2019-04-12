require 'faraday'
require 'zip'
require 'prawn'

module Award
  def fetch_top_contributors(repo)
    match_res =/github.com\/(\w+)\/(\w+)/.match(repo)
    
    return nil unless match_res

    host, repo = match_res[1..2]
    resp = Faraday.get("https://api.github.com/repos/#{host}/#{repo}/contributors")

    JSON.parse(resp.body)[0..2].map { |c| c["login"] }
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
  
  extend self
end
