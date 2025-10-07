# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "ipa.demo1.freeipa.org")
    VCR.use_cassette("authenticator/login_success") do
      @client = Fripa::Client.new(username: "admin", password: "Secret123")
    end
  end

  def test_initialize_with_credentials
    VCR.use_cassette("authenticator/login_success") do
      client = Fripa::Client.new(username: "testuser", password: "testpass")
      assert_equal "testuser", client.username
      assert_equal "testpass", client.password
      assert_equal Fripa.config, client.config
    end
  end

  def test_initialize_with_custom_config
    custom_config = Fripa::Configuration.new(host: "ipa.demo1.freeipa.org", verify_ssl: false)
    VCR.use_cassette("authenticator/login_success") do
      client = Fripa::Client.new(username: "admin", password: "secret", config: custom_config)
      assert_equal custom_config, client.config
      assert_equal "admin", client.username
      assert_equal "secret", client.password
    end
  end

  def test_call_authenticates_automatically_if_no_session
    VCR.use_cassette("client/auto_authenticate_and_call") do
      result = @client.call("user_find", ["admin"])

      refute_nil @client.session_cookie
      assert_nil result["error"]
      assert result.dig("result", "result").is_a?(Array)
    end
  end

  def test_call_with_options
    VCR.use_cassette("client/call_with_options") do
      result = @client.call("user_find", ["admin"], { all: true })

      assert_nil result["error"]
      assert result.dig("result", "result").is_a?(Array)
    end
  end
end
