# frozen_string_literal: true

module Fripa
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      def call(method, args = [], options = {})
        client.call(method, args, options)
      end

      def validate_identifier!(identifier, name = "identifier")
        raise ArgumentError, "#{name} is required" if identifier.to_s.strip.empty?
      end

      def validate_attributes!(attributes)
        raise ArgumentError, "attributes cannot be empty" if attributes.empty?
      end

      def validate_required_fields!(attributes, required_fields)
        missing = required_fields.reject { |field| attributes.key?(field) }
        return if missing.empty?

        raise ArgumentError, "Missing required fields: #{missing.join(", ")}"
      end
    end
  end
end
