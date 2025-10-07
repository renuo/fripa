# frozen_string_literal: true

require "test_helper"

class TestAuthenticator < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(
      host: "ipa.demo1.freeipa.org",
      username: "admin",
      password: "Secret123"
    )
    @authenticator = Fripa::Authenticator.new
  end

  def test_initialize_with_default_config
    authenticator = Fripa::Authenticator.new
    assert_equal Fripa.config, authenticator.config
  end

  def test_initialize_with_custom_config
    custom_config = Fripa::Configuration.new(host: "custom.example.com")
    authenticator = Fripa::Authenticator.new(custom_config)
    assert_equal custom_config, authenticator.config
  end

  def test_login_raises_on_blank_username
    Fripa.config.username = ""

    error = assert_raises(ArgumentError) do
      @authenticator.login!
    end
    assert_equal "Username cannot be blank", error.message
  end

  def test_login_raises_on_blank_password
    Fripa.config.password = nil

    error = assert_raises(ArgumentError) do
      @authenticator.login!
    end
    assert_equal "Password cannot be blank", error.message
  end

  def test_login_success
    VCR.use_cassette("authenticator/login_success") do
      @authenticator.login!

      refute_nil Fripa.config.session_cookie
      assert_match(/ipa_session=/, Fripa.config.session_cookie)
    end
  end

  def test_login_with_invalid_credentials
    Fripa.config.password = "WrongPassword"

    VCR.use_cassette("authenticator/login_invalid_credentials") do
      error = assert_raises(Fripa::AuthenticationError) do
        @authenticator.login!
      end
      assert_match(/Login failed/, error.message)
    end
  end
end
