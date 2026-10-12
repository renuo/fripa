# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "test.example.com")
  end

  def test_initialize_with_parameters
    config = Fripa::Configuration.new(host: "ipa.example.com", verify_ssl: false)

    assert_equal "ipa.example.com", config.host
    refute config.verify_ssl
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
    refute Fripa.config.verify_ssl
  end

  def test_config_assignment_with_hash
    Fripa.config = { host: "hash.example.com", verify_ssl: false }

    assert_equal "hash.example.com", Fripa.config.host
    refute Fripa.config.verify_ssl
  end

  def test_config_direct_attribute_modification
    Fripa.config.host = "direct.example.com"
    Fripa.config.verify_ssl = false

    assert_equal "direct.example.com", Fripa.config.host
    refute Fripa.config.verify_ssl
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

  def test_build_uri_raises_without_host
    config = Fripa::Configuration.new
    error = assert_raises(ArgumentError) do
      config.base_url
    end
    assert_equal "host is required", error.message
  end

  def test_scheme_is_case_insensitive
    config = Fripa::Configuration.new(host: "ipa.example.com", scheme: "HTTPS")

    assert_equal "https://ipa.example.com", config.base_url.to_s
  end

  def test_build_uri_raises_on_unknown_scheme
    config = Fripa::Configuration.new(host: "ipa.example.com", scheme: "ftp")
    error = assert_raises(ArgumentError) { config.base_url }

    assert_equal "scheme must be one of: http, https", error.message
  end

  def test_defaults_for_new_options
    config = Fripa::Configuration.new(host: "ipa.example.com")

    assert_equal "2.251", config.api_version
    assert_nil config.timeout
    assert_nil config.open_timeout
    assert_nil config.adapter
    refute config.raise_on_partial_failure
  end
end
