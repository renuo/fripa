# frozen_string_literal: true

require "faraday"
require "uri"

module Fripa
  class Authenticator
    LOGIN_PATH = "/ipa/session/login_password"
    CONTENT_TYPE = "application/x-www-form-urlencoded"

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def login!
      validate_credentials!
      response = perform_login

      raise AuthenticationError, "Login failed: #{response.status}" unless response.success?

      response.headers["set-cookie"]
    end

    private

    def validate_credentials!
      raise ArgumentError, "Username cannot be blank" if client.username.to_s.strip.empty?
      raise ArgumentError, "Password cannot be blank" if client.password.to_s.strip.empty?
    end

    def perform_login
      connection.post(LOGIN_PATH) do |request|
        request.headers["Content-Type"] = CONTENT_TYPE
        request.headers["Referer"] = "#{client.config.base_url}/ipa"
        request.body = URI.encode_www_form(user: client.username, password: client.password)
      end
    end

    def connection
      @connection ||= Faraday.new(url: client.config.base_url.to_s) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.ssl.verify = client.config.verify_ssl
      end
    end
  end
end
