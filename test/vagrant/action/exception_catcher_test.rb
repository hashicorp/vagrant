require "test_helper"

class ExceptionCatcherTest < Test::Unit::TestCase
  setup do
    @klass = Class.new
    @klass.send(:include, Vagrant::Action::ExceptionCatcher)
    @env = Vagrant::Action::Environment.new(mock_environment)

    @instance = @klass.new
  end

  should "run block and return result if no exception" do
    result = @instance.catch_action_exception(@env) do
      true
    end

    assert result
    assert !@env.error?
  end

  should "run block and return false with error environment on exception" do
    result = @instance.catch_action_exception(@env) do
      raise Vagrant::Action::ActionException.new(:foo, :foo => :bar)
    end

    assert !result
    assert @env.error?
    assert_equal :foo, @env.error.first
  end
end
