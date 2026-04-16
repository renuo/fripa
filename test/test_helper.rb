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
end

Minitest::Test.include FripaTestHelper
