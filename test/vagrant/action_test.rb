require "test_helper"

class ActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action
  end

  context "with a class" do
    teardown do
      @klass.actions.clear
    end

    should "be able to register an action" do
      @klass.register(:foo, :bar)
      assert @klass.actions.has_key?(:foo)
      assert_equal :bar, @klass.actions[:foo]
    end

    should "be able to retrieve an action using []" do
      @klass.register(:foo, :bar)
      assert_equal :bar, @klass[:foo]
    end
  end

  context "with an instance" do
    setup do
      @instance = @klass.new(mock_environment)
    end

    teardown do
      @klass.actions.clear
    end

    should "raise an exception if a nil action is given" do
      assert_raises(Vagrant::Exceptions::UncallableAction) { @instance.run(nil) }
      assert_raises(Vagrant::Exceptions::UncallableAction) { @instance.run(:dontexist) }
    end

    should "run the callable item with the proper context" do
      callable = mock("callable")
      callable.expects(:call).with() do |env|
        assert env.kind_of?(Vagrant::Action::Environment)
        assert_equal @instance.env, env.env
        true
      end

      @instance.run(callable)
    end

    should "run the callable with the passed in options if given" do
      options = {
        :key => :value,
        :another => %W[1 2 3]
      }

      callable = mock("callable")
      callable.expects(:call).with() do |env|
        assert env.kind_of?(Vagrant::Action::Environment)
        assert_equal @instance.env, env.env

        options.each do |k,v|
          assert_equal v, env[k]
        end

        true
      end

      @instance.run(callable, options)
    end

    should "run the registered callable if a symbol is given" do
      callable = mock("callable")
      callable.expects(:call).once

      @klass.register(:call, callable)
      @instance.run(:call)
    end

    should "run the given class if a class is given" do
      callable = Class.new do
        def initialize(app, env); end
      end

      callable.any_instance.expects(:call).with() do |env|
        assert_equal :foo, env[:bar]
        true
      end

      @instance.run(callable, :bar => :foo)
    end
  end
end
