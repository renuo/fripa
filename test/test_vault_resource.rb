# frozen_string_literal: true

require "test_helper"
require "openssl"

class TestVaultResource < Minitest::Test
  def setup
    @client = fripa_client(cassette: "vault/login")
  end

  def test_add_vault
    cn = "fripa-test-add"
    VCR.use_cassette("vault/add") do
      result = @client.vault.add(cn)

      assert_nil result["error"]
      assert_equal cn, result.dig("result", "result", "cn", 0)

      @client.vault.delete(cn)
    end
  end

  def test_add_raises_on_blank_cn
    error = assert_raises(ArgumentError) { @client.vault.add("") }
    assert_equal "cn is required", error.message
  end

  def test_show_vault
    cn = "fripa-test-show"
    VCR.use_cassette("vault/show") do
      @client.vault.add(cn)
      result = @client.vault.show(cn)

      assert_nil result["error"]
      assert_equal cn, result.dig("result", "result", "cn", 0)

      @client.vault.delete(cn)
    end
  end

  def test_show_raises_on_blank_cn
    error = assert_raises(ArgumentError) { @client.vault.show("") }
    assert_equal "cn is required", error.message
  end

  def test_archive_vault
    cn = "fripa-test-arc4"
    VCR.use_cassette("vault/archive") do
      @client.vault.add(cn)
      result = @client.vault.archive(cn, data: "my-kek-value")

      assert_nil result["error"]

      @client.vault.delete(cn)
    end
  end

  def test_archive_raises_on_blank_cn
    error = assert_raises(ArgumentError) { @client.vault.archive("", data: "my-kek-value") }
    assert_equal "cn is required", error.message
  end

  def test_delete_vault
    cn = "fripa-test-delete"
    VCR.use_cassette("vault/delete") do
      @client.vault.add(cn)
      result = @client.vault.delete(cn)

      assert_nil result["error"]
    end
  end

  def test_delete_raises_on_blank_cn
    error = assert_raises(ArgumentError) { @client.vault.delete("") }
    assert_equal "cn is required", error.message
  end

  def test_retrieve_vault
    cn = "fripa-test-retrieve"
    with_fixed_session_key do
      VCR.use_cassette("vault/retrieve") do
        @client.vault.add(cn)
        @client.vault.archive(cn, data: "my-kek-value")
        assert_equal "my-kek-value", @client.vault.retrieve(cn)
        @client.vault.delete(cn)
      end
    end
  end

  private

  def with_fixed_session_key
    fixed_key = File.binread(File.expand_path("fixtures/session_key.bin", __dir__))
    original = Fripa::VaultTransport.method(:generate_session_key)
    Fripa::VaultTransport.define_singleton_method(:generate_session_key) { fixed_key }
    yield
  ensure
    Fripa::VaultTransport.define_singleton_method(:generate_session_key, &original)
  end

  def test_retrieve_raises_on_blank_cn
    error = assert_raises(ArgumentError) { @client.vault.retrieve("") }
    assert_equal "cn is required", error.message
  end

  def test_add_member
    cn = "fripa-test-member"
    VCR.use_cassette("vault/add_member") do
      @client.vault.add(cn, shared: true)
      result = @client.vault.add_member(cn, user: ["admin"], shared: true)

      assert_nil result["error"]

      @client.vault.delete(cn, shared: true)
    end
  end

  def test_add_member_raises_on_blank_cn
    error = assert_raises(ArgumentError) { @client.vault.add_member("") }
    assert_equal "cn is required", error.message
  end
end
