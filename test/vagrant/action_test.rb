require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action
  end

  context "with an instance" do
    setup do
      @instance = @klass.new(mock_environment)
    end

    teardown do
      @klass.actions.clear
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

    should "error and exit if erroneous environment results" do
      callable = lambda do |env|
        env.error!(:key, :foo => :bar)
      end

      @instance.expects(:error_and_exit).with(:key, :foo => :bar)
      @instance.run(callable)
    end
  end
end
