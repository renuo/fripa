# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new
  end

  def test_initialize_with_parameters
    config = Fripa::Configuration.new(host: "ipa.example.com", username: "admin", password: "secret")
    assert_equal "ipa.example.com", config.host
    assert_equal "admin", config.username
    assert_equal "secret", config.password
    assert_equal true, config.verify_ssl
  end

  def test_configure_with_block
    Fripa.configure do |config|
      config.host = "test.example.com"
      config.username = "testuser"
    end

    assert_equal "test.example.com", Fripa.config.host
    assert_equal "testuser", Fripa.config.username
  end

  def test_config_assignment_with_hash
    Fripa.config = { host: "hash.example.com", username: "hashuser", password: "secret" }

    assert_equal "hash.example.com", Fripa.config.host
    assert_equal "hashuser", Fripa.config.username
    assert_equal "secret", Fripa.config.password
  end

  def test_config_direct_attribute_modification
    Fripa.config.host = "direct.example.com"
    Fripa.config.username = "directuser"

    assert_equal "direct.example.com", Fripa.config.host
    assert_equal "directuser", Fripa.config.username
  end

  def test_urls_construction
    config = Fripa::Configuration.new(host: "ipa.example.com")
    assert_equal "https://ipa.example.com", config.base_url.to_s
    assert_equal "https://ipa.example.com/ipa/session/login_password", config.login_url.to_s
    assert_equal "https://ipa.example.com/ipa/session/json", config.api_url.to_s
  end
end
