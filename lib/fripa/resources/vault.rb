# frozen_string_literal: true

require "base64"

module Fripa
  module Resources
    class Vault < Base
      def show(cn, **scope)
        validate_identifier!(cn, "cn")
        call("vault_show", [cn], scope)
      end

      def add(cn, **scope)
        validate_identifier!(cn, "cn")
        call("vault_add_internal", [cn], { ipavaulttype: "standard" }.merge(scope))
      end

      def archive(cn, data:, **scope)
        validate_identifier!(cn, "cn")
        transport_cert_der = fetch_transport_cert
        payload = VaultTransport.wrap(data, transport_cert_der)
        call("vault_archive_internal", [cn], binary_encode(payload).merge(wrapping_algo: VaultTransport::WRAPPING_ALGO).merge(scope))
      end

      def retrieve(cn, **scope)
        validate_identifier!(cn, "cn")
        session_key = VaultTransport.generate_session_key
        response = call_retrieve(cn, session_key, **scope)
        result = response.dig("result", "result")

        VaultTransport.decrypt(
          vault_data: extract_value(result["vault_data"]),
          nonce: extract_value(result["nonce"]),
          session_key: session_key
        )
      end

      def add_member(cn, **scope)
        validate_identifier!(cn, "cn")
        call("vault_add_member", [cn], scope)
      end

      def delete(cn, **scope)
        validate_identifier!(cn, "cn")
        call("vault_del", [cn], scope)
      end

      private

      def fetch_transport_cert
        response = call("vaultconfig_show", [], { all: true })
        cert = response["result"]["result"]["transport_cert"]
        Base64.decode64(cert.is_a?(Hash) ? cert["__base64__"] : cert)
      end

      def call_retrieve(cn, session_key, **scope)
        cert = OpenSSL::X509::Certificate.new(fetch_transport_cert)
        encrypted_key = cert.public_key.public_encrypt(session_key, VaultTransport::RSA_PADDING)

        call("vault_retrieve_internal", [cn], {
          session_key: { "__base64__" => Base64.strict_encode64(encrypted_key) },
          wrapping_algo: VaultTransport::WRAPPING_ALGO
        }.merge(scope))
      end

      def binary_encode(hash)
        hash.transform_values { |v| { "__base64__" => v } }
      end

      def extract_value(value)
        value.is_a?(Hash) ? value["__base64__"] : value
      end
    end
  end
end
