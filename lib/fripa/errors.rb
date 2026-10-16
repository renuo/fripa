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

  # Raised by Client#batch! when one or more commands of the batch failed. #errors lists them:
  # { index:, method:, code:, name:, message: }. #code and #message are those of the first one.
  # #data holds every result of the batch.
  class BatchError < ResponseError
    attr_reader :errors

    def initialize(errors, results)
      @errors = errors
      first = errors.first
      super(code: first[:code], message: "#{first[:method]}: #{first[:message]}", data: results)
    end

    # Raises a BatchError if any result of the batch response holds an error.
    def self.check!(commands, response)
      results = response.dig("result", "results") || []
      errors = results.each_with_index.filter_map do |result, index|
        next unless result["error"]

        { index: index, method: commands[index].first, code: result["error_code"],
          name: result["error_name"], message: result["error"] }
      end
      raise new(errors, results) if errors.any?
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
