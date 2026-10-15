# frozen_string_literal: true

require "faraday"
require "json"

module Fripa
  class Client
    API_PATH = "/ipa/session/json"
    API_VERSION = Configuration::DEFAULT_API_VERSION
    UNAUTHORIZED = 401

    attr_reader :config, :username, :password
    attr_accessor :session_cookie

    # Does not connect: the client logs in on the first call, or when you call login!.
    # Without username, it uses config.username and config.password. With a
    # username, it never uses the password from the configuration.
    # Give a session_cookie from an earlier login to skip the login request.
    # Without a password, an expired session raises AuthenticationError.
    def initialize(username: nil, password: nil, config: nil, session_cookie: nil)
      @config = config || Fripa.config
      @username = username || @config.username
      @password = username ? password : password || @config.password
      @session_cookie = session_cookie unless session_cookie.to_s.empty?
      @logged_in = !@session_cookie.nil?
      authenticator.validate_credentials! unless @logged_in
    end

    def users
      @users ||= Resources::User.new(self)
    end

    def groups
      @groups ||= Resources::Group.new(self)
    end

    def vault
      @vault ||= Resources::Vault.new(self)
    end

    def authenticator
      @authenticator ||= Authenticator.new(self)
    end

    # Logs in now and returns the session cookie. Raises AuthenticationError
    # if the credentials are wrong.
    def login!
      self.session_cookie = authenticator.login!
      @logged_in = true
      session_cookie
    end

    def logged_in?
      @logged_in
    end

    def call(method, args = [], options = {})
      login! unless logged_in?
      response = perform_request(method, args, options)
      response = reauthenticate_and_retry(method, args, options) if response.status == UNAUTHORIZED

      raise ConnectionError, "API call failed: #{response.status}" unless response.success?

      parse_response(response)
    end

    # Sends several commands in one HTTP request. Each command is
    # [method, args = [], options = {}]. Per-command errors are not raised:
    # check result["result"]["results"][i]["error"].
    def batch(*commands)
      requests = commands.map do |method, args = [], options = {}|
        { method: method, params: [args, options.merge(version: config.api_version)] }
      end
      call("batch", requests)
    end

    # Shared by Authenticator, so login and API calls reuse one connection.
    def connection
      @connection ||= Faraday.new(url: config.base_url.to_s, request: request_options) do |f|
        f.adapter(*Array(config.adapter || Faraday.default_adapter))
        f.ssl.verify = config.verify_ssl
      end
    end

    def referer
      @referer ||= "#{config.base_url}/ipa"
    end

    def inspect
      "#<#{self.class.name} username=#{username.inspect} host=#{config.host.inspect}>"
    end

    private

    def reauthenticate_and_retry(method, args, options)
      raise AuthenticationError, "Session expired and no password to log in again" if password.to_s.empty?

      login!
      perform_request(method, args, options)
    end

    def perform_request(method, args, options)
      connection.post(API_PATH) do |request|
        request.headers["Content-Type"] = "application/json"
        request.headers["Referer"] = referer
        request.headers["Cookie"] = session_cookie
        request.body = build_request_body(method, args, options).to_json
      end
    rescue Faraday::Error => e
      raise ConnectionError, "API call failed: #{e.message}"
    end

    def build_request_body(method, args, options)
      {
        method: method,
        params: [args, options.merge(version: config.api_version)],
        id: 0
      }
    end

    def parse_response(response)
      parsed = JSON.parse(response.body)
      raise ConnectionError, "API call failed: unexpected response" unless parsed.is_a?(Hash)

      raise_if_error(parsed)
      parsed
    rescue JSON::ParserError
      raise ConnectionError, "API call failed: invalid JSON response"
    end

    def raise_if_error(parsed)
      if (error = parsed["error"])
        raise ResponseError.new(code: error["code"], message: error["message"] || error["name"], data: error["data"])
      end

      return unless config.raise_on_partial_failure

      failed = parsed.dig("result", "failed")
      raise PartialFailureError, failed if PartialFailureError.failures(failed).any?
    end

    def request_options
      { timeout: config.timeout, open_timeout: config.open_timeout }.compact
    end
  end
end
