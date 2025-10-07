# frozen_string_literal: true

require "test_helper"

class TestUserResource < Minitest::Test
  def setup
    Fripa.config = Fripa::Configuration.new(host: "ipa.demo1.freeipa.org")
    VCR.use_cassette("authenticator/login_success") do
      @client = Fripa::Client.new(username: "admin", password: "Secret123")
    end
  end

  def test_find_all_users
    VCR.use_cassette("user/find_all") do
      result = @client.users.find

      assert_nil result["error"]
      assert result.dig("result", "result").is_a?(Array)
    end
  end

  def test_find_user_by_uid
    VCR.use_cassette("user/find_by_uid") do
      result = @client.users.find("admin")

      assert_nil result["error"]
      assert result.dig("result", "result").is_a?(Array)
    end
  end

  def test_show_user
    VCR.use_cassette("user/show") do
      result = @client.users.show("admin")

      assert_nil result["error"]
      assert_equal "admin", result.dig("result", "result", "uid", 0)
    end
  end

  def test_show_user_raises_on_blank_uid
    error = assert_raises(ArgumentError) do
      @client.users.show("")
    end
    assert_equal "uid is required", error.message
  end

  def test_add_user
    VCR.use_cassette("user/add") do
      result = @client.users.add("fripauser001", givenname: "Fripa", sn: "User", cn: "Fripa User")

      assert_nil result["error"]
      assert_equal "fripauser001", result.dig("result", "result", "uid", 0)
    end
  end

  def test_add_user_raises_on_blank_uid
    error = assert_raises(ArgumentError) do
      @client.users.add("", givenname: "Test", sn: "User", cn: "Test User")
    end
    assert_equal "uid is required", error.message
  end

  def test_add_user_raises_on_missing_required_fields
    error = assert_raises(ArgumentError) do
      @client.users.add("testuser", givenname: "Test")
    end
    assert_match(/Missing required fields/, error.message)
  end

  def test_mod_user
    VCR.use_cassette("user/mod") do
      result = @client.users.mod("employee", mail: "employee-#{Time.now.to_i}@demo1.freeipa.org")

      assert_nil result["error"]
    end
  end

  def test_mod_user_raises_on_blank_uid
    error = assert_raises(ArgumentError) do
      @client.users.mod("", mail: "test@example.com")
    end
    assert_equal "uid is required", error.message
  end

  def test_mod_user_raises_on_empty_attributes
    error = assert_raises(ArgumentError) do
      @client.users.mod("testuser")
    end
    assert_equal "attributes cannot be empty", error.message
  end

  def test_delete_user
    VCR.use_cassette("user/delete") do
      @client.users.add("temp_delete_user", givenname: "Temp", sn: "User", cn: "Temp User")
      result = @client.users.delete("temp_delete_user")

      assert_nil result["error"]
    end
  end

  def test_delete_user_raises_on_blank_uid
    error = assert_raises(ArgumentError) do
      @client.users.delete("")
    end
    assert_equal "uid is required", error.message
  end

  def test_passwd
    VCR.use_cassette("user/passwd") do
      # Create user first, then change password
      @client.users.add("passwdtest", givenname: "Password", sn: "Test", cn: "Password Test", userpassword: "OldPass123")
      result = @client.users.passwd("passwdtest", "NewPass123", "OldPass123")

      assert_nil result["error"]
    end
  end

  def test_passwd_raises_on_blank_uid
    error = assert_raises(ArgumentError) do
      @client.users.passwd("", "newpass", "oldpass")
    end
    assert_equal "uid is required", error.message
  end

  def test_passwd_raises_on_blank_new_password
    error = assert_raises(ArgumentError) do
      @client.users.passwd("employee", "", "Secret123")
    end
    assert_equal "new_password cannot be blank", error.message
  end

  def test_passwd_raises_on_blank_current_password
    error = assert_raises(ArgumentError) do
      @client.users.passwd("employee", "NewSecret123", "")
    end
    assert_equal "current_password cannot be blank", error.message
  end
end
