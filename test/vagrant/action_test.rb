require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action
  end

  context "with an instance" do
    setup do
      @instance = @klass.new(mock_environment)
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
  end
end
