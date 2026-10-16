# frozen_string_literal: true

require "test_helper"
require "openssl"

class TestVaultBatch < Minitest::Test
  def setup
    @client = fripa_client(cassette: "vault/login")
  end

  def test_add_command
    assert_equal ["vault_add_internal", ["v1"], { ipavaulttype: "standard", shared: true }],
                 @client.vault.add_command("v1", shared: true)
  end

  def test_add_member_command
    assert_equal ["vault_add_member", ["v1"], { user: ["alice"], shared: true }],
                 @client.vault.add_member_command("v1", user: ["alice"], shared: true)
  end

  def test_delete_command
    assert_equal ["vault_del", ["v1"], { shared: true }], @client.vault.delete_command("v1", shared: true)
  end

  def test_archive_command_wraps_the_data_with_the_transport_certificate
    key = OpenSSL::PKey::RSA.generate(2048)
    Fripa::Resources::Vault.transport_cert(@client.config.base_url.to_s) { self_signed_cert(key).to_der }

    method, args, options = @client.vault.archive_command("v1", data: "secret", shared: true)

    assert_equal ["vault_archive_internal", ["v1"]], [method, args]
    assert_equal({ wrapping_algo: "aes-128-cbc", shared: true }, options.slice(:wrapping_algo, :shared))
    payload = options.slice(:vault_data, :session_key, :nonce).transform_values { |value| value["__base64__"] }

    assert_equal "secret", Fripa::VaultTransport.unwrap(**payload, private_key: key)
  end

  def test_commands_raise_on_blank_cn
    %i[add_command add_member_command delete_command].each do |command|
      assert_raises(ArgumentError) { @client.vault.public_send(command, "") }
    end
    assert_raises(ArgumentError) { @client.vault.archive_command("", data: "secret") }
  end

  def test_batch_provisions_and_deletes_vaults_in_one_request_each
    cns = %w[fripa-test-batch-1 fripa-test-batch-2]
    with_fixed_session_key do
      VCR.use_cassette("vault/batch") do
        vault = @client.vault
        @client.batch!(*cns.flat_map do |cn|
          [vault.add_command(cn), vault.archive_command(cn, data: "kek-#{cn}"),
           vault.add_member_command(cn, user: ["admin"])]
        end)

        assert_equal "kek-fripa-test-batch-2", vault.retrieve("fripa-test-batch-2")
        assert_equal ["admin"], vault.show("fripa-test-batch-1").dig("result", "result", "member_user")

        @client.batch!(*cns.map { |cn| vault.delete_command(cn) })
      end
    end
  end

  def test_batch_bang_raises_batch_error_with_the_failed_commands
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") do
        [200, {}, json_rpc_body(result: { count: 2, results: [
                                  { error: nil, result: {} },
                                  { error: "v2: vault not found", error_code: 4001, error_name: "NotFound" }
                                ] })]
      end
    end

    error = nil

    with_stubbed_connection(@client, stubs) do
      error = assert_raises(Fripa::BatchError) { @client.batch!(%w[vault_del v1], %w[vault_del v2]) }
    end

    assert_equal 4001, error.code
    assert_equal "vault_del: v2: vault not found", error.message
    assert_equal [{ index: 1, method: "vault_del", code: 4001, name: "NotFound", message: "v2: vault not found" }],
                 error.errors
    assert_kind_of Fripa::ResponseError, error
  end

  def test_batch_bang_forgets_the_transport_certificate_when_an_archive_fails
    key = @client.config.base_url.to_s
    Fripa::Resources::Vault.transport_cert(key) { "old-cert" }
    stub_batch_error("vault_archive_internal", code: 4301)

    assert_raises(Fripa::BatchError) { batch_with_stubbed_error(%w[vault_archive_internal v1]) }
    assert_equal "new-cert", Fripa::Resources::Vault.transport_cert(key) { "new-cert" }
  end

  def test_batch_bang_keeps_the_transport_certificate_when_another_command_fails
    key = @client.config.base_url.to_s
    Fripa::Resources::Vault.transport_cert(key) { "old-cert" }
    stub_batch_error("vault_del", code: 2100)

    assert_raises(Fripa::BatchError) { batch_with_stubbed_error(%w[vault_del v1]) }
    assert_equal "old-cert", Fripa::Resources::Vault.transport_cert(key) { "new-cert" }
  end

  def test_batch_bang_returns_the_response_when_every_command_succeeds
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") { [200, {}, json_rpc_body(result: { count: 1, results: [{ error: nil }] })] }
    end

    with_stubbed_connection(@client, stubs) do
      assert_equal 1, @client.batch!(%w[vault_del v1]).dig("result", "count")
    end
  end

  private

  def stub_batch_error(method, code:)
    @error_stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/ipa/session/json") do
        [200, {}, json_rpc_body(result: { count: 1, results: [{ error: "#{method} failed", error_code: code }] })]
      end
    end
  end

  def batch_with_stubbed_error(command)
    with_stubbed_connection(@client, @error_stubs) { @client.batch!(command) }
  end

  def self_signed_cert(key)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=test")
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    cert
  end
end
