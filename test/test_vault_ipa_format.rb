# frozen_string_literal: true

require "test_helper"
require "openssl"

# Checks the vault payload against what the ipa CLI expects, with a fake KRA:
# the fake decrypts what fripa sends and encrypts what fripa reads.
class TestVaultIpaFormat < Minitest::Test
  class FakeKRA
    attr_reader :calls, :stored

    def initialize
      @key = OpenSSL::PKey::RSA.generate(2048)
      @cert = build_cert
      @calls = []
    end

    def call(method, _args = [], options = {})
      @calls << method
      { "result" => { "result" => send(method, options) } }
    end

    private

    def vaultconfig_show(_options)
      { "transport_cert" => { "__base64__" => Base64.strict_encode64(@cert.to_der) } }
    end

    def vault_archive_internal(options)
      @stored = Fripa::VaultTransport.unwrap(
        vault_data: options[:vault_data]["__base64__"], session_key: options[:session_key]["__base64__"],
        nonce: options[:nonce]["__base64__"], private_key: @key
      )
      {}
    end

    def vault_retrieve_internal(options)
      return {} if @stored.nil?

      session_key = @key.private_decrypt(Base64.decode64(options[:session_key]["__base64__"]),
                                         Fripa::VaultTransport::RSA_PADDING)
      nonce = OpenSSL::Random.random_bytes(16)
      data = Fripa::VaultTransport.encrypt_data(@stored, session_key, nonce)
      { "vault_data" => { "__base64__" => Base64.strict_encode64(data) },
        "nonce" => { "__base64__" => Base64.strict_encode64(nonce) } }
    end

    def build_cert
      OpenSSL::X509::Certificate.new.tap do |cert|
        cert.version = 2
        cert.serial = 1
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=kra")
        cert.public_key = @key.public_key
        cert.not_before = Time.now
        cert.not_after = Time.now + 3600
        cert.sign(@key, OpenSSL::Digest.new("SHA256"))
      end
    end
  end

  def setup
    @kra = FakeKRA.new
    @vault = Fripa::Resources::Vault.new(@kra)
  end

  def test_archive_stores_raw_bytes_by_default
    @vault.archive("kek", data: "my-kek-value")

    assert_equal "my-kek-value", @kra.stored
  end

  def test_archive_with_ipa_format_stores_the_ipa_cli_envelope
    @vault.archive("kek", data: "my-kek-value", ipa_format: true)

    assert_equal({ "data" => Base64.strict_encode64("my-kek-value") }, JSON.parse(@kra.stored))
  end

  def test_retrieve_with_ipa_format_reads_the_ipa_cli_envelope
    @vault.archive("kek", data: "my-kek-value", ipa_format: true)

    assert_equal "my-kek-value", @vault.retrieve("kek", ipa_format: true)
  end

  def test_retrieve_round_trip_with_raw_bytes
    @vault.archive("kek", data: "my-kek-value")

    assert_equal "my-kek-value", @vault.retrieve("kek")
  end

  def test_retrieve_returns_nil_for_empty_vault
    assert_nil @vault.retrieve("kek")
  end

  def test_transport_certificate_is_fetched_once
    @vault.archive("kek", data: "a")
    @vault.retrieve("kek")
    @vault.retrieve("kek")

    assert_equal 1, @kra.calls.count("vaultconfig_show")
  end
end
