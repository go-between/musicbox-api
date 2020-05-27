# frozen_string_literal: true

Yt.configure do |config|
  config.api_key = ENV["YOUTUBE_KEY"]
end

ActiveSupport::Notifications.subscribe 'request.yt' do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)

  event.payload[:request_uri] #=> #<URI::HTTPS URL:https://www.googleapis.com/youtube/v3/channels?id=UCxO1tY8h1AhOz0T4ENwmpow&part=snippet>
  event.payload[:method] #=> :get
  event.payload[:response] #=> #<Net::HTTPOK 200 OK readbody=true>

  event.end #=> 2014-08-22 16:57:17 -0700
  event.duration #=> 141.867 (ms)
end
