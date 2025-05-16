# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails'
gem "rails"
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
# gem 'puma'

gem "puma"

# Use postgresql as the database for Active Record
gem "pg"

gem "dotenv-rails"
gem "health_check"
gem "passenger"
gem "rack-cors"
gem "redis"
gem "sidekiq"

gem "devise"
gem "doorkeeper"
gem "graphiql-rails"
gem "graphql"

gem "airbrake"
gem "foreman"

gem "terminal-table"

# Cron-like task scheduler
gem "clockwork"

group :development do
  gem "listen"
  gem "rubocop-rails-omakase", require: false
  gem "spring"
  gem "spring-watcher-listen"
end

group :development, :test do
  gem "bullet"
  gem "pry-byebug"
  gem "webmock"
end

group :test do
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "rspec-sidekiq"
end
