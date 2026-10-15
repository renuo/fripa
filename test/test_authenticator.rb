# frozen_string_literal: true

require "test_helper"

class TestAuthenticator < Minitest::Test
  def setup
    @client = fripa_client(cassette: "authenticator/login_success")
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
        Fripa::Client.new(username: "admin", password: "WrongPassword").login!
      end
      assert_match(/Login failed/, error.message)
    end
  end

  def test_login_keeps_only_cookie_name_and_value
    header = "ipa_session=MagBearerToken=abc%3d;path=/ipa;httponly;secure;"
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/login_password") { [200, { "Set-Cookie" => header }, ""] }
    end

    with_stubbed_connection(@client, stubs) do
      assert_equal "ipa_session=MagBearerToken=abc%3d", @client.authenticator.login!
    end
  end

  def test_login_keeps_every_cookie_when_header_is_joined
    header = "ipa_session=abc; Expires=Wed, 21 Oct 2026 07:28:00 GMT; path=/ipa, other=1; secure"
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/login_password") { [200, { "Set-Cookie" => header }, ""] }
    end

    with_stubbed_connection(@client, stubs) do
      assert_equal "ipa_session=abc; other=1", @client.authenticator.login!
    end
  end

  def test_login_returns_nil_without_session_cookie
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.post("/ipa/session/login_password") { [200, {}, ""] } }

    with_stubbed_connection(@client, stubs) do
      assert_nil @client.authenticator.login!
    end
  end

  def test_login_wraps_network_errors
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/login_password") { raise Faraday::TimeoutError, "execution expired" }
    end

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::ConnectionError) { @client.authenticator.login! }

      assert_equal "Login failed: execution expired", error.message
    end
  end
end
