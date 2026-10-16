# frozen_string_literal: true

module Fripa
  # Batch calls for Fripa::Client: many commands in one HTTP request.
  module Batch
    # Sends several commands in one HTTP request. Each command is
    # [method, args = [], options = {}]. Per-command errors are not raised:
    # check result["result"]["results"][i]["error"].
    def batch(*commands)
      requests = commands.map do |method, args = [], options = {}|
        { method: method, params: [args, options.merge(version: config.api_version)] }
      end
      call("batch", requests)
    end

    # Commands wrapped with the vault transport certificate (see Resources::Vault#archive_command).
    TRANSPORT_COMMANDS = %w[vault_archive_internal vault_retrieve_internal].freeze

    # Like batch, but raises Fripa::BatchError when any command failed.
    # Like Resources::Vault#archive, a failed transport command forgets the certificate, so the next
    # call fetches it again (e.g. after the server renewed it).
    def batch!(*commands)
      batch(*commands).tap { |response| BatchError.check!(commands, response) }
    rescue BatchError => e
      forget_transport_cert_after(e)
      raise
    end

    private

    def forget_transport_cert_after(error)
      return unless error.errors.any? do |failed|
        TRANSPORT_COMMANDS.include?(failed[:method]) && failed[:code] != Resources::Vault::NOT_FOUND
      end

      Resources::Vault.forget_transport_cert(config.base_url.to_s)
    end
  end
end
