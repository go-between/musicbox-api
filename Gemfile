# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "6.0.2.2"
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
# gem 'puma', '~> 3.7'

# Use postgresql as the database for Active Record
gem "pg", "1.2.1"
gem "yt", "0.32.5"

gem "dotenv-rails", "2.7.5"
gem "health_check", "3.0.0"
gem "passenger", "6.0.4"
gem "rack-cors", "1.1.1"
gem "redis", "4.1.3"
gem "sidekiq", "6.0.4"

gem "devise", "4.7.1"
gem "doorkeeper", "5.2.3"
gem "graphiql-rails", "1.7.0"
gem "graphql", "1.9.16"

gem "skylight", "4.2.2"

group :development do
  gem "listen", "3.2.1"
  gem "rubocop", "0.78.0"
  gem "rubocop-rspec", "1.37.1"
  gem "spring", "2.1.0"
  gem "spring-watcher-listen", "2.0.1"
end

group :development, :test do
  gem "bullet", "6.1.0"
  gem "pry-byebug", "3.7.0"
end

group :test do
  gem "database_cleaner", "1.7.0"
  gem "factory_bot_rails", "5.1.1"
  gem "rspec-rails", "4.0.0.beta3"
  gem "rspec-sidekiq", "3.0.3"
end
