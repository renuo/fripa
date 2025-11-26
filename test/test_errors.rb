# frozen_string_literal: true

require "test_helper"

class TestResponseError < Minitest::Test
  def test_stores_code_and_message
    error = Fripa::ResponseError.new(code: 4001, message: "user not found")

    assert_equal 4001, error.code
    assert_equal "user not found", error.message
    assert_nil error.data
  end

  def test_stores_optional_data
    error = Fripa::ResponseError.new(
      code: 4002,
      message: "validation failed",
      data: { field: "uid", reason: "already exists" }
    )

    assert_equal 4002, error.code
    assert_equal "validation failed", error.message
    assert_equal({ field: "uid", reason: "already exists" }, error.data)
  end

  def test_inherits_from_fripa_error
    error = Fripa::ResponseError.new(code: 1, message: "test")

    assert_kind_of Fripa::Error, error
    assert_kind_of StandardError, error
  end

  def test_can_be_rescued_as_standard_error
    raised = false

    begin
      raise Fripa::ResponseError.new(code: 1, message: "test")
    rescue StandardError
      raised = true
    end

    assert raised
  end
end
