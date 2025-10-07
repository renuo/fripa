# frozen_string_literal: true

require "uri"

# Fripa configuration
module Fripa
  # Configuration for Fripa
  class Configuration
    attr_accessor :host, :username, :password, :verify_ssl, :session_cookie

    def initialize(host: nil, username: nil, password: nil, verify_ssl: true)
      @host = host
      @username = username
      @password = password
      @verify_ssl = verify_ssl
      @session_cookie = nil
    end

    def base_url
      URI::HTTPS.build(host: host)
    end

    def login_url
      URI::HTTPS.build(host: host, path: "/ipa/session/login_password")
    end

    def api_url
      URI::HTTPS.build(host: host, path: "/ipa/session/json")
    end
  end

  class << self
    def config
      @config ||= Configuration.new
    end

    def config=(value)
      @config = case value
                when Hash
                  Configuration.new(**value)
                when Configuration
                  value
                else
                  raise ArgumentError, "config must be a Hash or Configuration instance"
                end
    end

    def configure
      yield(config)
    end
  end
end
