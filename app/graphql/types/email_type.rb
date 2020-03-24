# frozen_string_literal: true

module Types
  class EmailType < Types::BaseScalar
    def self.coerce_input(value, _context)
      value&.downcase
    end

    def self.coerce_result(value, _context)
      value
    end
  end
end
