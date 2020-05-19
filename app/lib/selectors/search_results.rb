# frozen_string_literal: true

module Selectors
  class SearchResults
    attr_reader :arel, :current_user, :to, :from, :lookahead
    def initialize(lookahead:)
      @arel = Message.arel_table
    end

    def search
      []
    end
  end
end
