# frozen_string_literal: true

module Fripa
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class ConnectionError < Error; end

  class ResponseError < Error
    attr_reader :code, :data

    def initialize(code:, message:, data: nil)
      @code = code
      @data = data
      super(message)
    end
  end

  # Raised when FreeIPA answers without an error but reports per-entry failures,
  # e.g. group_add_member with a user that does not exist or is already a member.
  # Only raised with config.raise_on_partial_failure = true.
  # #data holds the full "failed" hash from the response.
  class PartialFailureError < ResponseError
    def initialize(failed)
      super(code: nil, message: self.class.first_reason(failed), data: failed)
    end

    def self.failures(failed)
      return [] unless failed.is_a?(Hash)

      failed.values.flat_map do |types|
        types.is_a?(Hash) ? types.values.flat_map { |entries| Array(entries) } : Array(types)
      end
    end

    def self.first_reason(failed)
      entry = failures(failed).first
      entry.is_a?(Array) ? entry.last.to_s : entry.to_s
    end
  end
end
