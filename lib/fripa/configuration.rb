# frozen_string_literal: true

require "uri"

# Fripa configuration
module Fripa
  # Configuration for Fripa
  class Configuration
    attr_accessor :host, :verify_ssl

    def initialize(host: nil, verify_ssl: true)
      @host = host
      @verify_ssl = verify_ssl
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
