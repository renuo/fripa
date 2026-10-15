# frozen_string_literal: true

require "faraday"
require "uri"

module Fripa
  class Authenticator
    LOGIN_PATH = "/ipa/session/login_password"
    CONTENT_TYPE = "application/x-www-form-urlencoded"
    # Splits a joined Set-Cookie header ("a=1; path=/, b=2") between cookies,
    # but not inside attributes such as "Expires=Wed, 21 Oct 2026".
    COOKIE_SEPARATOR = /,\s*(?=[^\s;,=]+=)/

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def login!
      validate_credentials!
      response = perform_login

      raise AuthenticationError, "Login failed: #{response.status}" unless response.success?

      session_cookie(response.headers["set-cookie"])
    end

    def inspect
      "#<#{self.class.name} username=#{client.username.inspect}>"
    end

    def validate_credentials!
      raise ArgumentError, "Username cannot be blank" if client.username.to_s.strip.empty?
      raise ArgumentError, "Password cannot be blank" if client.password.to_s.strip.empty?
    end

    private

    def perform_login
      client.connection.post(LOGIN_PATH) do |request|
        request.headers["Content-Type"] = CONTENT_TYPE
        request.headers["Referer"] = client.referer
        request.body = login_body
      end
    rescue Faraday::Error => e
      raise ConnectionError, "Login failed: #{e.message}"
    end

    def login_body
      URI.encode_www_form(user: client.username, password: client.password)
    end

    # Keeps only "name=value" pairs: attributes like path, httponly or secure
    # must not be sent back in the Cookie header. Returns nil without a
    # Set-Cookie header, as before (recorded test cassettes often drop it).
    def session_cookie(header)
      return nil if header.nil?

      header.split(COOKIE_SEPARATOR).map { |cookie| cookie.split(";").first.to_s.strip }.reject(&:empty?).join("; ")
    end
  end
end
