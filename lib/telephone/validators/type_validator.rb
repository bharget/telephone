# frozen_string_literal: true

require "active_model"

module Telephone
  class TypeValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      expected_type = options[:with]

      return if value.is_a?(expected_type)

      record.errors.add(
        attribute,
        :invalid_type,
        **options.except(:with).merge(type: type_name(expected_type))
      )
    end

    private

    def type_name(type)
      type.name || type.to_s
    end
  end
end
