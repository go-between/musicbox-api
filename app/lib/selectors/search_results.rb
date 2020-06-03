# frozen_string_literal: true

module Selectors
  class SearchResults
    attr_reader :user, :lookahead
    def initialize(user:, lookahead:)
      @user = user
      @lookahead = lookahead
    end

    def search(query:)
      songs = from_all_songs(query)
      return songs if songs.present?

      youtube_results = from_youtube(query)
      return youtube_results if youtube_results.present?

      []
    end

    private

    def from_all_songs(query)
      Song
        .where(Song.arel_table[:name].matches("%#{query}%"))
        .where.not(id: LibraryRecord.select(:song_id).where(user: user))
    end

    def from_youtube(query)
      Yt::Collections::Videos.new.where(
        q: query,
        type: "video",
        max_results: 4,
        order: "relevance"
      )
    end
  end
end
