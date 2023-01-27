# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "6.1.4"
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
# gem 'puma', '~> 3.7'

gem "puma", "5.2.2"

# Use postgresql as the database for Active Record
gem "pg", "1.2.1"

gem "dotenv-rails", "2.7.6"
gem "health_check", "3.0.0"
gem "passenger", "6.0.4"
gem "rack-cors", "1.1.1"
gem "redis", "4.1.3"
gem "sidekiq", "6.0.4"

gem "devise", "4.8.0"
gem "doorkeeper", "5.2.5"
gem "graphiql-rails", "1.7.0"
gem "graphql", "1.10.10"

gem "airbrake", "9.5.5"
gem "foreman", "0.87.2"

gem 'terminal-table'

# Cron-like task scheduler
gem 'clockwork', '3.0.0'

group :development do
  gem "listen", "3.2.1"
  gem "rubocop", "0.78.0"
  gem "rubocop-rspec", "1.37.1"
  gem "spring", "2.1.0"
  gem "spring-watcher-listen", "2.0.1"
end

group :development, :test do
  gem "bullet", "6.1.4"
  gem "pry-byebug", "3.9.0"
  gem "webmock", "3.8.3"
end

group :test do
  gem "database_cleaner", "1.7.0"
  gem "factory_bot_rails", "5.1.1"
  gem "rspec-rails", "4.0.0.beta3"
  gem "rspec-sidekiq", "3.0.3"
end
