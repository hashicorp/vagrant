require "test_helper"

class ActionEnvironmentTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Environment
    @instance = @klass.new(mock_environment)
  end

  should "default values to those on the env" do
    @instance.env.stubs(:key).returns("value")
    assert_equal "value", @instance["key"]
  end

  should "setup the logger" do
    assert_equal @instance.env.logger, @instance.logger
  end

  should "not be erroneous initially" do
    assert !@instance.error?
  end

  should "mark as erroneous" do
    @instance.error!(:key)
    assert_equal [:key, {}], @instance.error
  end

  should "properly report erroneous" do
    @instance.error!(:key)
    assert @instance.error?
  end

  should "report interrupted if interrupt error" do
    assert !@instance.interrupted?
    @instance.error!(:interrupt)
    assert @instance.interrupted?
  end

  should "have indifferent access" do
    @instance[:foo] = :bar
    @instance["bar"] = :baz

    assert_equal :bar, @instance["foo"]
    assert_equal :baz, @instance[:bar]
  end
end
