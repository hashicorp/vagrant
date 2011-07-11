require "test_helper"
require "logger"

class ActionWardenTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Warden
    @instance = @klass.new([], {})
  end

  context "initializing" do
    should "finalize the middleware" do
      env = new_env
      middleware = [1,2,3]
      middleware.each do |m|
        @klass.any_instance.expects(:finalize_action).with(m, env).returns(m)
      end
      @warden = @klass.new(middleware, env)
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
      env = new_env
      action = mock('action')
      action.expects(:call).with(env)
      @instance.actions << action
      @instance.call(env)
    end

    should "begin recovery sequence when the called action raises an exception" do
      class Foo
        def initialize(*args); end
        def call(env)
          raise "An exception"
        end
      end

      @instance.actions << Foo.new
      @instance.expects(:begin_rescue).with() do |env|
        assert env["vagrant.error"].is_a?(RuntimeError)
        true
      end
      assert_raises(RuntimeError) { @instance.call(new_env) }
    end

    should "not begin recovery sequence if a SystemExit is raised" do
      class Foo
        def initialize(*args); end
        def call(env)
          # Raises a system exit
          abort
        end
      end

      @instance.actions << Foo.new
      @instance.expects(:begin_rescue).never
      assert_raises(SystemExit) { @instance.call(new_env) }
    end

    should "raise interrupt if the environment is interupted" do
      env = new_env
      env.expects(:interrupted?).returns(true)
      @instance.actions << lambda { |env| }

      assert_raises(Vagrant::Errors::VagrantInterrupt) {
        @instance.call(env)
      }
    end
  end

  context "recover" do
    should "call recover on all items in the stack" do
      env = new_env
      seq = sequence("sequence")
      @instance.stack = [rescueable_mock("action"), rescueable_mock("another")]
      @instance.stack.each do |action|
        action.expects(:recover).with(env).in_sequence(seq)
      end

      @instance.begin_rescue(env)
    end
  end

  def new_env
    env = Vagrant::Action::Environment.new(nil)
    env["logger"] = Logger.new(nil)
    env
  end

  def rescueable_mock(name)
    mock_action = mock(name)
    mock_action.stubs(:respond_to?).with(:recover).returns(true)
    mock_action
  end
end
