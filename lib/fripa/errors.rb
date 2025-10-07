# frozen_string_literal: true

module Fripa
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class ConnectionError < Error; end
end
