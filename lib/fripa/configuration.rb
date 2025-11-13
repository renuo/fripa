# frozen_string_literal: true

require "uri"

# Fripa configuration
module Fripa
  # Configuration for Fripa
  class Configuration
    attr_accessor :host, :port, :scheme, :verify_ssl

    def initialize(host:, port: nil, scheme: "https", verify_ssl: true)
      @host = host
      @port = port
      @scheme = scheme
      @verify_ssl = verify_ssl
    end

    def base_url
      build_uri
    end

    def login_url
      build_uri(path: "/ipa/session/login_password")
    end

    def api_url
      build_uri(path: "/ipa/session/json")
    end

    private

    def build_uri(path: nil)
      uri_class = scheme == "https" ? URI::HTTPS : URI::HTTP
      uri_class.build(host: host, port: port, path: path)
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
