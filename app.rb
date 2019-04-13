require 'roda'
require 'json'

require_relative './lib/award.rb'

class App < Roda
  plugin :render, engine: :slim
  route do |r|
    r.root do
      render('main')
    end

    r.is('repo') do
      url = request.params['url']
      fetch_result = Award.fetch_top_contributors(url)

      if fetch_result.success?
        @contributors = fetch_result.value!
        render('repo')
      else
        @error = fetch_result.failure.to_s
        render('main')
      end
    end

    r.is('pdf') do
      name = request.params['name']
      place = request.params['place']

      response.headers['Content-Type'] = 'text/pdf'
      if request.params['download']
        response.headers['Content-Disposition'] = "attachment; filename=#{name}.pdf"
      end

      Award.pdf_io(name, place)
    end

    r.is('zip') do
      response.headers['Content-Type'] = 'application/octet-stream'
      response.headers['Content-Disposition'] = "attachment; filename=awards.zip"
      Award.zip_contributors(request.params.map { |name, place| {name: name, place: place}})
    end
  end

  def contributors_to_params(contributors)
    contributors.each_with_index.map { |name, place| "#{name}=#{place+1}" }.join('&')
  end
end
