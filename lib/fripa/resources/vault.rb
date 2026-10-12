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

      # ipa_format: true stores the data like `ipa vault-archive`, so the ipa CLI can read it.
      # The default (false) stores the raw bytes, as in previous versions.
      def archive(cn, data:, ipa_format: false, **scope)
        validate_identifier!(cn, "cn")
        data = VaultTransport.to_ipa_format(data) if ipa_format
        payload = VaultTransport.wrap(data, transport_cert_der)
        call("vault_archive_internal", [cn],
             binary_encode(payload).merge(wrapping_algo: VaultTransport::WRAPPING_ALGO).merge(scope))
      end

      # ipa_format: true reads data stored by `ipa vault-archive` (or archive with ipa_format: true).
      # Returns nil if the vault has no data.
      def retrieve(cn, ipa_format: false, **scope)
        validate_identifier!(cn, "cn")
        session_key = VaultTransport.generate_session_key
        result = call_retrieve(cn, session_key, **scope).dig("result", "result")
        return nil unless result&.key?("vault_data")

        data = VaultTransport.decrypt(
          vault_data: extract_value(result["vault_data"]),
          nonce: extract_value(result["nonce"]),
          session_key: session_key
        )
        ipa_format ? VaultTransport.from_ipa_format(data) : data
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

      # The KRA transport certificate does not change between calls, so we
      # fetch it once per client (the ipa CLI caches it too).
      def transport_cert_der
        @transport_cert_der ||= fetch_transport_cert
      end

      def fetch_transport_cert
        response = call("vaultconfig_show", [], { all: true })
        Base64.decode64(extract_value(response.dig("result", "result", "transport_cert")))
      end

      def call_retrieve(cn, session_key, **scope)
        encrypted_key = VaultTransport.encrypt_session_key(session_key, transport_cert_der)

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
