# frozen_string_literal: true

log_level = {
  "debug" => Logger::DEBUG,
  "info" => Logger::INFO,
  "warn" => Logger::WARN,
  "error" => Logger::ERROR
}[ENV["LOG_LEVEL"]] || Logger::WARN

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["SIDEKIQ_REDIS_URL"] }
  config.logger.level = log_level
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["SIDEKIQ_REDIS_URL"] }
end
