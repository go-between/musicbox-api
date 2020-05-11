# frozen_string_literal: true

module Types
  class OrderType < Types::BaseInputObject
    argument :field, Types::OrderedFieldType, required: true
    argument :direction, Types::OrderedDirectionType, required: true
  end
end
