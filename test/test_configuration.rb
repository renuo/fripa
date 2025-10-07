# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new
  end

  def test_initialize_with_parameters
    config = Fripa::Configuration.new(host: "ipa.example.com", verify_ssl: false)
    assert_equal "ipa.example.com", config.host
    assert_equal false, config.verify_ssl
  end

  def test_configure_with_block
    Fripa.configure do |config|
      config.host = "test.example.com"
      config.verify_ssl = false
    end

    assert_equal "test.example.com", Fripa.config.host
    assert_equal false, Fripa.config.verify_ssl
  end

  def test_config_assignment_with_hash
    Fripa.config = { host: "hash.example.com", verify_ssl: false }

    assert_equal "hash.example.com", Fripa.config.host
    assert_equal false, Fripa.config.verify_ssl
  end

  def test_config_direct_attribute_modification
    Fripa.config.host = "direct.example.com"
    Fripa.config.verify_ssl = false

    assert_equal "direct.example.com", Fripa.config.host
    assert_equal false, Fripa.config.verify_ssl
  end

  def test_urls_construction
    config = Fripa::Configuration.new(host: "ipa.example.com")
    assert_equal "https://ipa.example.com", config.base_url.to_s
    assert_equal "https://ipa.example.com/ipa/session/login_password", config.login_url.to_s
    assert_equal "https://ipa.example.com/ipa/session/json", config.api_url.to_s
  end

  def test_config_assignment_raises_on_invalid_type
    error = assert_raises(ArgumentError) do
      Fripa.config = "invalid"
    end
    assert_equal "config must be a Hash or Configuration instance", error.message
  end
end
