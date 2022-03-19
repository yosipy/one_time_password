FROM ruby:3.0.2

RUN apt-get update -qq && apt-get install -y \
  postgresql-client

RUN gem update bundler

WORKDIR /app

COPY Gemfile /app/

# comment out: arise `executor failed running [/bin/sh -c bundle install]: exit code: 15`
# RUN bundle install
