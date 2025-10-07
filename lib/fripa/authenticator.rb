# frozen_string_literal: true

require "faraday"
require "uri"

module Fripa
  class Authenticator
    LOGIN_PATH = "/ipa/session/login_password"
    CONTENT_TYPE = "application/x-www-form-urlencoded"

    attr_reader :config

    def initialize(config = nil)
      @config = config || Fripa.config
    end

    def login!
      validate_credentials!
      response = perform_login

      raise AuthenticationError, "Login failed: #{response.status}" unless response.success?

      config.session_cookie = extract_session_cookie(response)
    end

    private

    def validate_credentials!
      raise ArgumentError, "Username cannot be blank" if config.username.to_s.strip.empty?
      raise ArgumentError, "Password cannot be blank" if config.password.to_s.strip.empty?
    end

    def perform_login
      connection.post(LOGIN_PATH) do |request|
        request.headers["Content-Type"] = CONTENT_TYPE
        request.headers["Referer"] = "#{config.base_url}/ipa"
        request.body = URI.encode_www_form(user: config.username, password: config.password)
      end
    end

    def extract_session_cookie(response)
      cookie = response.headers["set-cookie"]
      raise AuthenticationError, "No session cookie received" unless cookie

      cookie
    end

    def connection
      @connection ||= Faraday.new(url: config.base_url.to_s) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.ssl.verify = config.verify_ssl
      end
    end
  end
end
