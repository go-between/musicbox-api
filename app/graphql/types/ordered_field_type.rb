# frozen_string_literal: true

module Types
  class OrderedFieldType < Types::BaseScalar
    def self.coerce_input(value, _context)
      value&.underscore
    end

    def self.coerce_result(value, _context)
      value&.camelize(:lower)
    end
  end
end
