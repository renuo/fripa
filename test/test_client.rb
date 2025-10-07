# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(
      host: "ipa.demo1.freeipa.org",
      username: "admin",
      password: "Secret123"
    )
    @client = Fripa::Client.new
  end

  def test_initialize_with_default_config
    client = Fripa::Client.new
    assert_equal Fripa.config, client.config
  end

  def test_initialize_with_custom_config
    custom_config = Fripa::Configuration.new(host: "custom.example.com")
    client = Fripa::Client.new(custom_config)
    assert_equal custom_config, client.config
  end

  def test_call_authenticates_automatically_if_no_session
    VCR.use_cassette("client/auto_authenticate_and_call") do
      result = @client.call("user_find", ["admin"])

      refute_nil Fripa.config.session_cookie
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
