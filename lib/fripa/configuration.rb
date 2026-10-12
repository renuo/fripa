# frozen_string_literal: true

require "uri"

# Fripa configuration
module Fripa
  # Configuration for Fripa
  class Configuration
    DEFAULT_API_VERSION = "2.251"
    SCHEMES = %w[http https].freeze

    attr_accessor :host, :port, :scheme, :verify_ssl, :api_version, :timeout, :open_timeout, :adapter,
                  :raise_on_partial_failure

    def initialize(host: nil, port: nil, scheme: "https", verify_ssl: true, api_version: DEFAULT_API_VERSION,
                   timeout: nil, open_timeout: nil, adapter: nil, raise_on_partial_failure: false)
      @host = host
      @port = port
      @scheme = scheme
      @verify_ssl = verify_ssl
      @api_version = api_version
      @timeout = timeout
      @open_timeout = open_timeout
      @adapter = adapter
      @raise_on_partial_failure = raise_on_partial_failure
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
      raise ArgumentError, "host is required" if host.to_s.empty?

      normalized_scheme = scheme.to_s.downcase
      raise ArgumentError, "scheme must be one of: #{SCHEMES.join(", ")}" unless SCHEMES.include?(normalized_scheme)

      uri_class = normalized_scheme == "https" ? URI::HTTPS : URI::HTTP
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
