# frozen_string_literal: true

require "test_helper"
require "openssl"

class TestVaultTransport < Minitest::Test
  def setup
    @key = OpenSSL::PKey::RSA.generate(2048)
    @cert = self_signed_cert(@key)
    @cert_der = @cert.to_der
  end

  def test_wrap_returns_required_keys
    result = Fripa::VaultTransport.wrap("secret-data", @cert_der)

    assert result.key?(:vault_data)
    assert result.key?(:session_key)
    assert result.key?(:nonce)
  end

  def test_wrap_values_are_base64
    result = Fripa::VaultTransport.wrap("secret-data", @cert_der)

    assert_match(%r{\A[A-Za-z0-9+/]+=*\z}, result[:vault_data])
    assert_match(%r{\A[A-Za-z0-9+/]+=*\z}, result[:session_key])
    assert_match(%r{\A[A-Za-z0-9+/]+=*\z}, result[:nonce])
  end

  def test_round_trip
    original = "my-super-secret-kek-value"
    wrapped = Fripa::VaultTransport.wrap(original, @cert_der)

    recovered = Fripa::VaultTransport.unwrap(
      vault_data: wrapped[:vault_data],
      session_key: wrapped[:session_key],
      nonce: wrapped[:nonce],
      private_key: @key
    )

    assert_equal original, recovered
  end

  def test_generate_transport_key_returns_rsa_key
    key = Fripa::VaultTransport.generate_transport_key

    assert_instance_of OpenSSL::PKey::RSA, key
    assert key.private?
  end

  private

  def self_signed_cert(key)
    cert = OpenSSL::X509::Certificate.new
    setup_cert_attributes(cert, key)
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  def setup_cert_attributes(cert, key)
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=test")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600
  end
end
