# frozen_string_literal: true

module Selectors
  class SearchResults
    attr_reader :user, :lookahead
    def initialize(user:, lookahead:)
      @user = user
      @lookahead = lookahead
    end

    def search(query:)
      library_records = from_library(query)
      return library_records if library_records.present?

      songs = from_all_songs(query)
      return songs if songs.present?

      youtube_results = from_youtube(query)
      return youtube_results if youtube_results.present?

      []
    end

    private

    def from_library(query)
      Selectors::LibraryRecords
        .new(lookahead: lookahead, user: user)
        .for_user
        .with_query(query)
        .without_pending_records
        .library_records
    end

    def from_all_songs(query)
      Song.where(Song.arel_table[:name].matches("%#{query}%"))
    end

    def from_youtube(query)
      Yt::Collections::Videos.new.where(q: query, type: "video")
    end
  end
end
