# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

module Fripa
  module VaultTransport
    CIPHER = "AES-128-CBC"
    WRAPPING_ALGO = "aes-128-cbc"
    KEY_SIZE = 16
    IV_SIZE = 16
    RSA_KEY_SIZE = 2048
    RSA_PADDING = OpenSSL::PKey::RSA::PKCS1_PADDING

    def self.generate_session_key
      OpenSSL::Random.random_bytes(KEY_SIZE)
    end

    def self.decrypt(vault_data:, nonce:, session_key:)
      decipher = OpenSSL::Cipher.new(CIPHER)
      decipher.decrypt
      decipher.key = session_key
      decipher.iv = Base64.decode64(nonce)
      decipher.update(Base64.decode64(vault_data)) + decipher.final
    end

    def self.wrap(data, transport_cert_der)
      session_key = generate_session_key
      nonce = OpenSSL::Random.random_bytes(IV_SIZE)
      vault_data = encrypt_data(data, session_key, nonce)
      encrypted_session_key = encrypt_session_key(session_key, transport_cert_der)

      {
        vault_data: Base64.strict_encode64(vault_data),
        session_key: Base64.strict_encode64(encrypted_session_key),
        nonce: Base64.strict_encode64(nonce)
      }
    end

    def self.encrypt_data(data, key, nonce)
      cipher = OpenSSL::Cipher.new(CIPHER).encrypt
      cipher.key = key
      cipher.iv = nonce
      cipher.update(data.b) + cipher.final
    end

    def self.encrypt_session_key(session_key, cert_der)
      cert = OpenSSL::X509::Certificate.new(cert_der)
      cert.public_key.public_encrypt(session_key, RSA_PADDING)
    end

    def self.unwrap(vault_data:, session_key:, nonce:, private_key:)
      decrypted_session_key = private_key.private_decrypt(Base64.decode64(session_key), RSA_PADDING)
      decrypt(vault_data: vault_data, nonce: nonce, session_key: decrypted_session_key)
    end

    # The ipa CLI (ipa vault-archive / vault-retrieve) stores {"data": base64(data)},
    # not the raw bytes. Use these to read or write vaults shared with the CLI.
    def self.to_ipa_format(data)
      JSON.generate("data" => Base64.strict_encode64(data))
    end

    def self.from_ipa_format(json)
      Base64.strict_decode64(JSON.parse(json).fetch("data"))
    end

    def self.generate_transport_key
      OpenSSL::PKey::RSA.generate(RSA_KEY_SIZE)
    end
  end
end
