# frozen_string_literal: true

require "test_helper"

class TestAuthenticator < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "ipa.demo1.freeipa.org")
    VCR.use_cassette("authenticator/login_success") do
      @client = Fripa::Client.new(username: "admin", password: "Secret123")
    end
  end

  def test_authenticator_returns_client
    assert_equal @client, @client.authenticator.client
  end

  def test_login_raises_on_blank_username
    error = assert_raises(ArgumentError) do
      Fripa::Client.new(username: "", password: "Secret123")
    end
    assert_equal "Username cannot be blank", error.message
  end

  def test_login_raises_on_blank_password
    error = assert_raises(ArgumentError) do
      Fripa::Client.new(username: "admin", password: nil)
    end
    assert_equal "Password cannot be blank", error.message
  end

  def test_login_success
    VCR.use_cassette("authenticator/login_success") do
      session_cookie = @client.authenticator.login!

      refute_nil session_cookie
      assert_match(/ipa_session=/, session_cookie)
    end
  end

  def test_login_with_invalid_credentials
    VCR.use_cassette("authenticator/login_invalid_credentials") do
      error = assert_raises(Fripa::AuthenticationError) do
        Fripa::Client.new(username: "admin", password: "WrongPassword")
      end
      assert_match(/Login failed/, error.message)
    end
  end
end
