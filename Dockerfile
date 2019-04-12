FROM ruby:2.6.2
WORKDIR app

COPY Gemfile Gemfile.lock /app/
RUN bundle install
ADD . .

CMD bundle exec rackup --host 0.0.0.0 --port $PORT
