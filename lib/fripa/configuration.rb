# frozen_string_literal: true

require "uri"

# Fripa configuration
module Fripa
  # Configuration for Fripa
  class Configuration
    DEFAULT_API_VERSION = "2.251"
    SCHEMES = %w[http https].freeze

    attr_accessor :host, :port, :scheme, :verify_ssl, :api_version, :timeout, :open_timeout, :adapter,
                  :raise_on_partial_failure, :username, :password

    # username and password are only used by Fripa.client and by
    # Fripa::Client.new without a username.
    def initialize(host: nil, port: nil, scheme: "https", verify_ssl: true, api_version: DEFAULT_API_VERSION,
                   timeout: nil, open_timeout: nil, adapter: nil, raise_on_partial_failure: false,
                   username: nil, password: nil)
      @host = host
      @port = port
      @scheme = scheme
      @verify_ssl = verify_ssl
      @api_version = api_version
      @timeout = timeout
      @open_timeout = open_timeout
      @adapter = adapter
      @raise_on_partial_failure = raise_on_partial_failure
      @username = username
      @password = password
    end

    # Values that change how a client connects or logs in. Fripa.client builds
    # a new client when they change.
    def options
      { host:, port:, scheme:, verify_ssl:, api_version:, timeout:, open_timeout:, adapter:,
        raise_on_partial_failure:, username:, password: }
    end

    def inspect
      "#<#{self.class.name} host=#{host.inspect} scheme=#{scheme.inspect} username=#{username.inspect}>"
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

  @client_lock = Mutex.new

  class << self
    def config
      @config ||= Configuration.new
    end

    # A client for the account in Fripa.config (username and password), shared
    # by the whole process. It is built on first use, and again when the
    # configuration changes. Use Fripa::Client.new for other accounts.
    def client
      @client_lock.synchronize do
        unless @client&.config.equal?(config) && @client_options == config.options
          @client = Client.new(config: config)
          @client_options = config.options
        end
        @client
      end
    end

    # Forgets the shared client (e.g. between tests). The next Fripa.client builds a new one.
    def reset_client!
      @client_lock.synchronize { @client = @client_options = nil }
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
