# frozen_string_literal: true

class TagLibraryRecord < ApplicationRecord
  self.table_name = "tags_songs"
  belongs_to :tag
  belongs_to :library_record
end
