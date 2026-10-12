# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def setup
    @client = fripa_client(cassette: "authenticator/login_success")
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
    custom_config = Fripa::Configuration.new(host: ENV.fetch("FREEIPA_HOST", "ipa.example.com"), verify_ssl: false)
    VCR.use_cassette("authenticator/login_success") do
      client = Fripa::Client.new(username: ENV.fetch("FREEIPA_USER", "admin"), password: "secret",
                                 config: custom_config)

      assert_equal custom_config, client.config
      assert_equal ENV.fetch("FREEIPA_USER", "admin"), client.username
      assert_equal "secret", client.password
    end
  end

  def test_call_authenticates_automatically_if_no_session
    VCR.use_cassette("client/auto_authenticate_and_call") do
      result = @client.call("user_find", ["admin"])

      refute_nil @client.session_cookie
      assert_nil result["error"]
      assert_kind_of Array, result.dig("result", "result")
    end
  end

  def test_call_with_options
    VCR.use_cassette("client/call_with_options") do
      result = @client.call("user_find", ["admin"], { all: true })

      assert_nil result["error"]
      assert_kind_of Array, result.dig("result", "result")
    end
  end

  def test_call_returns_response_with_failed_entries_by_default
    failed = { member: { user: [["employee", "This entry is already a member"]], group: [] } }
    body = json_rpc_body(result: { completed: 0, failed: failed, result: {} })
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.post("/ipa/session/json") { [200, {}, body] } }

    with_stubbed_connection(@client, stubs) do
      result = @client.call("group_add_member", ["editors"], { user: ["employee"] })

      assert_equal [["employee", "This entry is already a member"]], result.dig("result", "failed", "member", "user")
    end
  end

  def test_call_raises_partial_failure_error_when_enabled
    failed = { member: { user: [["brcostanzo", "Insufficient access: write privilege denied"]], group: [] } }
    body = json_rpc_body(result: { completed: 0, failed: failed, result: {} })
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.post("/ipa/session/json") { [200, {}, body] } }
    @client.config.raise_on_partial_failure = true

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::PartialFailureError) do
        @client.call("group_add_member", ["editors"], { user: ["brcostanzo"] })
      end

      assert_kind_of Fripa::ResponseError, error
      assert_equal "Insufficient access: write privilege denied", error.message
      assert_equal [["brcostanzo", "Insufficient access: write privilege denied"]], error.data.dig("member", "user")
    end
  ensure
    @client.config.raise_on_partial_failure = false
  end

  def test_call_does_not_raise_when_failed_lists_are_empty
    body = json_rpc_body(result: { completed: 1, failed: { member: { user: [], group: [] } }, result: {} })
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.post("/ipa/session/json") { [200, {}, body] } }
    @client.config.raise_on_partial_failure = true

    with_stubbed_connection(@client, stubs) do
      result = @client.call("group_add_member", ["editors"], { user: ["employee"] })

      assert_equal 1, result.dig("result", "completed")
    end
  ensure
    @client.config.raise_on_partial_failure = false
  end

  def test_call_raises_connection_error_on_http_failure
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") { [500, {}, "Internal Server Error"] }
    end

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::ConnectionError) { @client.call("user_find", ["admin"]) }

      assert_equal "API call failed: 500", error.message
    end
  end

  def test_call_logs_in_again_when_session_expired
    responses = [[401, {}, ""], [200, {}, json_rpc_body(result: { result: "pong" })]]
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") { responses.shift }
      stub.post("/ipa/session/login_password") { [200, { "Set-Cookie" => "ipa_session=fresh; path=/ipa" }, ""] }
    end

    with_stubbed_connection(@client, stubs) do
      result = @client.call("ping")

      assert_equal "pong", result.dig("result", "result")
      assert_equal "ipa_session=fresh", @client.session_cookie
    end
  end

  def test_call_logs_in_again_only_once
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") { [401, {}, ""] }
      stub.post("/ipa/session/login_password") { [200, { "Set-Cookie" => "ipa_session=fresh" }, ""] }
    end

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::ConnectionError) { @client.call("ping") }

      assert_equal "API call failed: 401", error.message
    end
  end

  def test_call_wraps_network_errors
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") { raise Faraday::ConnectionFailed, "Connection refused" }
    end

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::ConnectionError) { @client.call("ping") }

      assert_equal "API call failed: Connection refused", error.message
    end
  end

  def test_call_wraps_invalid_json
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") { [200, {}, "<html>maintenance</html>"] }
    end

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::ConnectionError) { @client.call("ping") }

      assert_equal "API call failed: invalid JSON response", error.message
    end
  end

  def test_call_rejects_json_that_is_not_an_object
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.post("/ipa/session/json") { [200, {}, "null"] } }

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::ConnectionError) { @client.call("ping") }

      assert_equal "API call failed: unexpected response", error.message
    end
  end

  def test_call_sends_configured_api_version
    sent = nil
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") do |env|
        sent = JSON.parse(env.body)
        [200, {}, json_rpc_body]
      end
    end
    @client.config.api_version = "2.230"

    with_stubbed_connection(@client, stubs) { @client.call("ping") }

    assert_equal "2.230", sent.dig("params", 1, "version")
  ensure
    @client.config.api_version = Fripa::Configuration::DEFAULT_API_VERSION
  end

  def test_batch_sends_all_commands_in_one_request
    sent = nil
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") do |env|
        sent = JSON.parse(env.body)
        [200, {}, json_rpc_body(result: { count: 2, results: [{ error: nil }, { error: nil }] })]
      end
    end

    with_stubbed_connection(@client, stubs) do
      result = @client.batch(["user_show", ["admin"]], ["group_find", [], { sizelimit: 0 }])

      assert_equal 2, result.dig("result", "count")
    end
    assert_equal "batch", sent["method"]
    assert_equal [
      { "method" => "user_show", "params" => [["admin"], { "version" => "2.251" }] },
      { "method" => "group_find", "params" => [[], { "sizelimit" => 0, "version" => "2.251" }] }
    ], sent.dig("params", 0)
  end

  def test_inspect_hides_password_and_session_cookie
    output = @client.inspect

    refute_includes output, @client.password
    refute_includes output, @client.session_cookie
    assert_includes output, @client.username
    refute_includes @client.authenticator.inspect, @client.password
  end

  def test_connection_uses_configured_timeouts_and_adapter
    config = Fripa::Configuration.new(host: "ipa.example.com", timeout: 5, open_timeout: 2, adapter: :test)
    client = Fripa::Client.allocate
    client.instance_variable_set(:@config, config)
    connection = client.connection

    assert_equal 5, connection.options.timeout
    assert_equal 2, connection.options.open_timeout
    assert_equal Faraday::Adapter::Test, connection.builder.adapter.klass
  end
end
