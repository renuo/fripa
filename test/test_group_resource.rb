# frozen_string_literal: true

require "test_helper"

class TestGroupResource < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "ipa.demo1.freeipa.org")
    VCR.use_cassette("authenticator/login_success") do
      @client = Fripa::Client.new(username: "admin", password: "Secret123")
    end
  end

  def test_find_all_groups
    VCR.use_cassette("group/find_all") do
      result = @client.groups.find

      assert_nil result["error"]
      assert result.dig("result", "result").is_a?(Array)
    end
  end

  def test_find_group_by_cn
    VCR.use_cassette("group/find_by_cn") do
      result = @client.groups.find("admins")

      assert_nil result["error"]
      assert result.dig("result", "result").is_a?(Array)
    end
  end

  def test_show_group
    VCR.use_cassette("group/show") do
      result = @client.groups.show("admins")

      assert_nil result["error"]
      assert_equal "admins", result.dig("result", "result", "cn", 0)
    end
  end

  def test_show_group_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.show("")
    end
    assert_equal "cn is required", error.message
  end

  def test_add_group
    VCR.use_cassette("group/add") do
      result = @client.groups.add("fripagem001", description: "Fripa Gem Group")

      assert_nil result["error"]
      assert_equal "fripagem001", result.dig("result", "result", "cn", 0)
    end
  end

  def test_add_group_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.add("", description: "Test")
    end
    assert_equal "cn is required", error.message
  end

  def test_mod_group
    VCR.use_cassette("group/mod") do
      result = @client.groups.mod("editors", description: "Updated at #{Time.now.to_i}")

      assert_nil result["error"]
    end
  end

  def test_mod_group_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.mod("", description: "Test")
    end
    assert_equal "cn is required", error.message
  end

  def test_mod_group_raises_on_empty_attributes
    error = assert_raises(ArgumentError) do
      @client.groups.mod("editors")
    end
    assert_equal "attributes cannot be empty", error.message
  end

  def test_add_member
    VCR.use_cassette("group/add_member") do
      result = @client.groups.add_member("editors", user: ["helpdesk"])

      assert_nil result["error"]
    end
  end

  def test_add_member_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.add_member("", user: ["employee"])
    end
    assert_equal "cn is required", error.message
  end

  def test_add_member_raises_on_empty_attributes
    error = assert_raises(ArgumentError) do
      @client.groups.add_member("editors")
    end
    assert_equal "attributes cannot be empty", error.message
  end

  def test_remove_member
    VCR.use_cassette("group/remove_member") do
      result = @client.groups.remove_member("editors", user: ["helpdesk"])

      assert_nil result["error"]
    end
  end

  def test_remove_member_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.remove_member("", user: ["employee"])
    end
    assert_equal "cn is required", error.message
  end

  def test_remove_member_raises_on_empty_attributes
    error = assert_raises(ArgumentError) do
      @client.groups.remove_member("editors")
    end
    assert_equal "attributes cannot be empty", error.message
  end

  def test_add_member_manager
    VCR.use_cassette("group/add_member_manager") do
      result = @client.groups.add_member_manager("employees", user: ["admin"])

      assert_nil result["error"]
    end
  end

  def test_add_member_manager_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.add_member_manager("", user: ["admin"])
    end
    assert_equal "cn is required", error.message
  end

  def test_add_member_manager_raises_on_empty_attributes
    error = assert_raises(ArgumentError) do
      @client.groups.add_member_manager("employees")
    end
    assert_equal "attributes cannot be empty", error.message
  end

  def test_remove_member_manager
    VCR.use_cassette("group/remove_member_manager") do
      result = @client.groups.remove_member_manager("employees", user: ["admin"])

      assert_nil result["error"]
    end
  end

  def test_remove_member_manager_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.remove_member_manager("", user: ["admin"])
    end
    assert_equal "cn is required", error.message
  end

  def test_remove_member_manager_raises_on_empty_attributes
    error = assert_raises(ArgumentError) do
      @client.groups.remove_member_manager("employees")
    end
    assert_equal "attributes cannot be empty", error.message
  end

  def test_delete_group
    VCR.use_cassette("group/delete") do
      @client.groups.add("temp_delete_group", description: "Temp group")
      result = @client.groups.delete("temp_delete_group")

      assert_nil result["error"]
    end
  end

  def test_delete_group_raises_on_blank_cn
    error = assert_raises(ArgumentError) do
      @client.groups.delete("")
    end
    assert_equal "cn is required", error.message
  end
end
