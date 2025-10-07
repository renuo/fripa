# frozen_string_literal: true

require "faraday"
require "json"

module Fripa
  class Client
    API_PATH = "/ipa/session/json"
    API_VERSION = "2.251"

    attr_reader :config, :username, :password
    attr_accessor :session_cookie

    def initialize(username:, password:, config: nil)
      @config = config || Fripa.config
      @username = username
      @password = password
      @session_cookie = nil
    end

    def users
      @users ||= Resources::User.new(self)
    end

    def groups
      @groups ||= Resources::Group.new(self)
    end

    def authenticator
      @authenticator ||= Authenticator.new(self)
    end

    def call(method, args = [], options = {})
      validate_session!

      response = perform_request(method, args, options)

      raise ConnectionError, "API call failed: #{response.status}" unless response.success?

      parse_response(response)
    end

    private

    def validate_session!
      return if session_cookie

      self.session_cookie = authenticator.login!
    end

    def perform_request(method, args, options)
      connection.post(API_PATH) do |request|
        request.headers["Content-Type"] = "application/json"
        request.headers["Referer"] = "#{config.base_url}/ipa"
        request.headers["Cookie"] = session_cookie
        request.body = build_request_body(method, args, options).to_json
      end
    end

    def build_request_body(method, args, options)
      {
        method: method,
        params: [args, options.merge(version: API_VERSION)],
        id: 0
      }
    end

    def parse_response(response)
      JSON.parse(response.body)
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
