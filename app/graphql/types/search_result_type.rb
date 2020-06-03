# frozen_string_literal: true

module Types
  class SearchResultType < Types::BaseUnion
    possible_types Types::SongType, Types::YoutubeResultType

    def self.resolve_type(object, _context)
      case object
      when Song
        Types::SongType
      when Yt::Models::Video
        Types::YoutubeResultType
      end
    end
  end
end
