require "test_helper"

class HashWithIndifferentAccessUtilTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Util::HashWithIndifferentAccess
    @instance = @klass.new
  end

  should "be a hash" do
    assert @instance.is_a?(Hash)
  end

  should "allow indifferent access when setting with a string" do
    @instance["foo"] = "bar"
    assert_equal "bar", @instance[:foo]
  end

  should "allow indifferent access when setting with a symbol" do
    @instance[:foo] = "bar"
    assert_equal "bar", @instance["foo"]
  end

  should "allow indifferent key lookup" do
    @instance["foo"] = "bar"
    assert @instance.key?(:foo)
    assert @instance.has_key?(:foo)
    assert @instance.include?(:foo)
    assert @instance.member?(:foo)
  end
end
