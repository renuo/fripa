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
end
