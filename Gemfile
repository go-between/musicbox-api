source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.2'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
# gem 'puma', '~> 3.7'

# Use postgresql as the database for Active Record
gem 'pg', '1.1.4'
gem 'yt', '0.32.4'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors', '1.0.3'
gem 'dotenv-rails', '2.7.5'
gem "passenger", "6.0.4"
gem 'redis', '4.1.3'
gem 'sidekiq', '6.0.0'

gem 'graphql', '1.9.12'
gem 'doorkeeper', '5.2.1'
gem 'devise', '4.7.1'

group :development do
  gem 'listen', '3.1.5'
  gem 'rubocop', '0.74.0'
  gem 'rubocop-rspec', '1.0.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '2.1.0'
  gem 'spring-watcher-listen', '2.0.1'
  gem 'action-cable-testing', '0.6.0'
end

group :development, :test do
  gem 'byebug', '11.0.1', platforms: %i[mri mingw x64_mingw]
end

group :test do
  gem 'factory_bot_rails', '5.1.0'
  gem 'rspec-rails', '3.8.2'
  gem 'rspec-sidekiq', '3.0.3'
  gem 'database_cleaner', '1.7.0'
end
