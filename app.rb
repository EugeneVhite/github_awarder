require 'roda'
require 'faraday'
require 'json'
require 'pry'
require 'pry-byebug'
require 'prawn'
require 'zip'

class App < Roda
  plugin :render, engine: :slim
  route do |r|
    r.root do
      render('main')
    end

    r.is('repo') do
      url = request.params['url']
      host, repo = /github.com\/(\w+)\/(\w+)/.match(url)[1..2]

      resp = Faraday.get("https://api.github.com/repos/#{host}/#{repo}/contributors")
      @contributors = JSON.parse(resp.body)[0..2].map { |c| c["login"] }

      render('repo')
    end

    r.is('award', String) do |name|
      response.headers['Content-Type'] = 'text/pdf'
      pdf_io(name, request.params['place'])
    end

    r.is('zip_award', String) do |name|
      response.headers['Content-Type'] = 'application/octet-stream'
      response.headers['Content-Disposition'] = "attachment; filename=#{name}.zip"
      stringio = Zip::OutputStream.write_buffer do |z_io|
        z_io.put_next_entry("#{name}.pdf")
        z_io.write pdf_io(name, request.params['place'])
      end
      stringio.rewind
      stringio.sysread
    end
  end

  def pdf_io(name, place)
    pdf = Prawn::Document.new
    pdf.text "Awards ##{place} to: #{name}"
    pdf.render
  end
end
