# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "test.example.com")
  end

  def test_initialize_with_parameters
    config = Fripa::Configuration.new(host: "ipa.example.com", verify_ssl: false)
    assert_equal "ipa.example.com", config.host
    assert_equal false, config.verify_ssl
  end

  def test_initialize_with_port
    config = Fripa::Configuration.new(host: "ipa.example.com", port: 8443)
    assert_equal "ipa.example.com", config.host
    assert_equal 8443, config.port
  end

  def test_initialize_with_http_scheme
    config = Fripa::Configuration.new(host: "localhost", port: 8080, scheme: "http")
    assert_equal "localhost", config.host
    assert_equal 8080, config.port
    assert_equal "http", config.scheme
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

  def test_urls_construction_with_custom_port
    config = Fripa::Configuration.new(host: "ipa.example.com", port: 8443)
    assert_equal "https://ipa.example.com:8443", config.base_url.to_s
    assert_equal "https://ipa.example.com:8443/ipa/session/login_password", config.login_url.to_s
    assert_equal "https://ipa.example.com:8443/ipa/session/json", config.api_url.to_s
  end

  def test_urls_construction_with_http_scheme
    config = Fripa::Configuration.new(host: "localhost", port: 8080, scheme: "http")
    assert_equal "http://localhost:8080", config.base_url.to_s
    assert_equal "http://localhost:8080/ipa/session/login_password", config.login_url.to_s
    assert_equal "http://localhost:8080/ipa/session/json", config.api_url.to_s
  end

  def test_config_assignment_raises_on_invalid_type
    error = assert_raises(ArgumentError) do
      Fripa.config = "invalid"
    end
    assert_equal "config must be a Hash or Configuration instance", error.message
  end

  def test_initialize_raises_without_host
    assert_raises(ArgumentError) do
      Fripa::Configuration.new
    end
  end
end
