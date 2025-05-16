# frozen_string_literal: true

class YoutubeClient
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def find(youtube_id)
    params = { part: "snippet,contentDetails", id: youtube_id, key: ENV["YOUTUBE_KEY"] }
    data = get("https://www.googleapis.com/youtube/v3/videos", params)&.dig(:items, 0)
    return nil if data.blank?

    OpenStruct.new(
      description: data.dig(:snippet, :description),
      duration: ActiveSupport::Duration.parse(data.dig(:contentDetails, :duration)).to_f,
      title: data.dig(:snippet, :title),
      thumbnail_url: data.dig(:snippet, :thumbnails, :default, :url),
      tags: data.dig(:snippet, :tags)
    )
  end

  def search(query)
    params = { part: "snippet", q: query, key: ENV["YOUTUBE_KEY"], type: "video" }
    data = get("https://www.googleapis.com/youtube/v3/search", params)&.dig(:items)
    return [] if data.blank?

    data.map do |d|
      OpenStruct.new(
        id: d.dig(:id, :videoId),
        description: d.dig(:snippet, :description),
        name: d.dig(:snippet, :title),
        thumbnail_url: d.dig(:snippet, :thumbnails, :default, :url)
      )
    end
  end

  private

  def get(url, params)
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      http.request(request)
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body, symbolize_names: true)
  end
end
