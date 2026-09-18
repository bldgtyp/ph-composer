# frozen_string_literal: true

require_relative "test_helper"

class ErrorsTest < PhComposerTestCase
  Namespace = PhComposer

  def test_extension_errors_belong_to_exactly_one_error_category
    classes, modules = extension_constants(Namespace)

    assert Namespace::Error < StandardError
    classes.each do |error_class|
      next if error_class == Namespace::Error

      assert error_class < Namespace::Error, "#{error_class} does not descend from PhComposer::Error"
      categories = [Namespace::UserError, Namespace::InternalError].count { |category| error_class <= category }
      assert_equal 1, categories, "#{error_class} must descend from exactly one error category"
    end
  end

  private

  def extension_constants(scope, visited = {}, classes = [], modules = [])
    return [classes, modules] if visited[scope.object_id]

    visited[scope.object_id] = true
    modules << scope
    scope.constants(false).each do |name|
      value = scope.const_get(name, false)
      classes << value if value.is_a?(Class) && value < StandardError
      extension_constants(value, visited, classes, modules) if value.is_a?(Module)
    end
    [classes.uniq, modules.uniq]
  end
end
