require "test_helper"

class ActionEnvironmentTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Environment
    @instance = @klass.new(vagrant_env)
  end

  should "be a hash with indifferent access" do
    assert @instance.is_a?(Vagrant::Util::HashWithIndifferentAccess)
  end

  should "default values to those on the env" do
    @instance.env.stubs(:key).returns("value")
    assert_equal "value", @instance["key"]
  end

  should "setup the UI" do
    assert_equal @instance.env.ui, @instance.ui
  end

  should "report interrupted if interrupt error" do
    assert !@instance.interrupted?
    @instance.interrupt!
    assert @instance.interrupted?
  end
end
