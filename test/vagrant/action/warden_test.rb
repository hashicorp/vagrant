require "test_helper"

class ActionWardenTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Warden
    @instance = @klass.new([], {})
    @klass.any_instance.stubs(:error_and_exit)
  end

  context "initializing" do
    should "finalize the middleware" do
      middleware = [1,2,3]
      middleware.each do |m|
        @klass.any_instance.expects(:finalize_action).with(m, {}).returns(m)
      end
      @warden = @klass.new(middleware, new_env)
      assert_equal @warden.actions, [1,2,3]
    end
  end

  context "setting up middleware" do
    should "make non-classes lambdas" do
      env = new_env
      env.expects(:foo).once

      func = lambda { |x| x.foo }
      @instance.finalize_action(func, env).call(env)
    end

    should "raise exception if given invalid middleware" do
      assert_raises(RuntimeError) {
        @instance.finalize_action(7, nil)
      }
    end
  end

  context "calling" do
    should "return if there are no actions to execute" do
      @instance.actions.expects(:pop).never
      assert !@instance.call(new_env)
    end

    should "move the last action to the front of the stack" do
      @instance.actions << lambda { |env| }
      assert @instance.stack.empty?
      @instance.call(new_env)
      assert !@instance.stack.empty?
      assert @instance.actions.empty?
    end

    should "call the next action" do
      action = mock('action')
      action.expects(:call).with({})
      @instance.actions << action
      @instance.call(new_env)
    end

    should "begin recovery sequence when the called action raises an exception" do
      class Foo
        def initialize(*args); end
        def call(env)
          raise "An exception"
        end
      end

      @instance.actions << Foo.new
      @instance.expects(:begin_rescue)
      assert_raises(RuntimeError) { @instance.call(new_env) }
    end

    def new_env_with_error
      env = new_env
      env.error!(:foo)
      env
    end
  end

  context "recover" do
    should "call recover on all items in the stack" do
      seq = sequence("sequence")
      @instance.stack = [rescueable_mock("action"), rescueable_mock("another")]
      @instance.stack.each do |action|
        action.expects(:recover).with(new_env).in_sequence(seq)
      end

      @instance.begin_rescue(new_env)
    end

    should "call exit if the environment is interupted" do
      @instance.expects(:exit)
      env = new_env
      env.expects(:interrupted?).returns(true)
      @instance.begin_rescue(env)
    end

    context "with many middleware" do
      should "not call middleware after" do

      end
    end
  end

  def new_env
    Vagrant::Action::Environment.new(nil)
  end

  def rescueable_mock(name)
    mock_action = mock(name)
    mock_action.stubs(:respond_to?).with(:recover).returns(true)
    mock_action
  end
end
