# frozen_string_literal: true

require "test_helper"

class TestLazyLogin < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "ipa.example.com", username: "admin", password: "admin-secret")
  end

  def test_new_client_does_not_send_requests
    stubs = Faraday::Adapter::Test::Stubs.new
    client = Fripa::Client.new(username: "alice", password: "secret")

    with_stubbed_connection(client, stubs) { refute_predicate client, :logged_in? }
  end

  def test_first_call_logs_in
    client = Fripa::Client.new(username: "alice", password: "secret")
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/login_password") { [200, { "Set-Cookie" => "ipa_session=a" }, ""] }
      stub.post("/ipa/session/json") { [200, {}, json_rpc_body(result: { result: "pong" })] }
    end

    with_stubbed_connection(client, stubs) { client.call("ping") }

    assert_predicate client, :logged_in?
    assert_equal "ipa_session=a", client.session_cookie
  end

  def test_login_bang_returns_the_session_cookie
    client = Fripa::Client.new(username: "alice", password: "secret")
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/login_password") { [200, { "Set-Cookie" => "ipa_session=a; path=/ipa" }, ""] }
    end

    with_stubbed_connection(client, stubs) { assert_equal "ipa_session=a", client.login! }
  end

  def test_login_bang_raises_on_wrong_credentials
    client = Fripa::Client.new(username: "alice", password: "wrong")
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.post("/ipa/session/login_password") { [401, {}, ""] } }

    with_stubbed_connection(client, stubs) do
      assert_raises(Fripa::AuthenticationError) { client.login! }
    end
  end

  def test_client_without_username_uses_configured_credentials
    client = Fripa::Client.new

    assert_equal "admin", client.username
    assert_equal "admin-secret", client.password
  end

  def test_client_with_username_never_uses_configured_password
    error = assert_raises(ArgumentError) { Fripa::Client.new(username: "alice") }

    assert_equal "Password cannot be blank", error.message
    assert_nil Fripa::Client.new(username: "alice", session_cookie: "ipa_session=a").password
  end

  def test_fripa_client_is_shared
    assert_same Fripa.client, Fripa.client
    assert_equal "admin", Fripa.client.username
  end

  def test_fripa_client_is_rebuilt_when_configuration_changes
    first = Fripa.client
    Fripa.config.password = "rotated"

    refute_same first, Fripa.client
    assert_equal "rotated", Fripa.client.password
  end

  def test_fripa_client_is_rebuilt_when_configuration_is_replaced
    first = Fripa.client
    Fripa.config = { host: "ipa.example.com", username: "admin", password: "admin-secret" }

    refute_same first, Fripa.client
  end

  def test_fripa_client_is_built_once_by_concurrent_threads
    clients = Array.new(8) { Thread.new { Fripa.client } }.map(&:value)

    assert_equal 1, clients.uniq(&:object_id).size
  end

  def test_reset_client_forgets_only_the_client
    first = Fripa.client
    Fripa.reset_client!

    assert_equal "admin", Fripa.config.username
    refute_same first, Fripa.client
  end

  def test_configuration_inspect_hides_password
    refute_includes Fripa.config.inspect, "admin-secret"
    assert_includes Fripa.config.inspect, "admin"
  end
end
