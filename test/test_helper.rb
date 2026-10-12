# frozen_string_literal: true

require "simplecov"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fripa"

require "minitest/autorun"
require "vcr"
require "uri"

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.hook_into :faraday
  # Every JSON-RPC call uses the same URL, so also match on the RPC method name.
  # Without this, VCR replays responses by position and a skipped call shifts all of them.
  config.register_request_matcher(:rpc_method) do |a, b|
    rpc = ->(request) { request.body.to_s.start_with?("{") ? JSON.parse(request.body)["method"] : nil }
    rpc.call(a) == rpc.call(b)
  end
  config.default_cassette_options = { match_requests_on: %i[method uri rpc_method] }
  config.filter_sensitive_data("ipa.example.com") { ENV.fetch("FREEIPA_HOST", "ipa.example.com") }
  if ENV["FREEIPA_PASSWORD"]
    config.filter_sensitive_data("<PASSWORD>") { ENV["FREEIPA_PASSWORD"] }
    config.filter_sensitive_data("<PASSWORD>") { URI.encode_www_form_component(ENV["FREEIPA_PASSWORD"]) }
  end
end

module FripaTestHelper
  def fripa_client(cassette:)
    Fripa.config = Fripa::Configuration.new(
      host: ENV.fetch("FREEIPA_HOST", "ipa.example.com"),
      verify_ssl: ENV.fetch("FREEIPA_VERIFY_SSL", "true") != "false"
    )
    VCR.use_cassette(cassette) do
      Fripa::Client.new(
        username: ENV.fetch("FREEIPA_USER", "admin"),
        password: ENV.fetch("FREEIPA_PASSWORD", "password")
      )
    end
  end

  # Replaces the HTTP connection of a client (used by login and API calls)
  # with Faraday test stubs, and checks that every stub was called.
  def with_stubbed_connection(client, stubs, &)
    connection = Faraday.new { |f| f.adapter :test, stubs }
    VCR.turned_off { client.stub(:connection, connection, &) }
    stubs.verify_stubbed_calls
  end

  def json_rpc_body(result: {}, error: nil)
    { result: result, error: error, id: 0 }.to_json
  end
end

Minitest::Test.include FripaTestHelper
