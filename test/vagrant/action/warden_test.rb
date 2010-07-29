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
      assert_equal @warden.actions, [3,2,1]
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
      @instance.actions << lambda {}
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

    should "begin rescue on environment error" do
      @instance.expects(:begin_rescue)
      @instance.actions << lambda {}
      @instance.actions.first.expects(:call).never
      @instance.call(new_env_with_error)
    end

    should "not call the next action on env err" do
      action = mock('action')
      action.expects(:call).never
      @instance.actions << action
      @instance.expects(:begin_rescue)
      @instance.call(new_env_with_error)
    end

    should "call begin rescue when the called action returns with an env error" do
      class Foo
        def initialize(*args); end
        def call(env)
          return env.error!(:foo)
        end
      end

      @instance.actions << Foo.new
      @instance.expects(:begin_rescue)
      @instance.call(new_env)
    end
    
    def new_env_with_error
      env = new_env
      env.error!(:foo)
      env
    end
  end

  context "rescue" do
    should "call rescue on all items in the stack" do
      mock_action = rescueable_mock("action")
      mock_action.expects(:rescue).times(2)
      @instance.stack = [mock_action, mock_action]
      @instance.begin_rescue(new_env)
    end

    should "call rescue on stack in reversed order" do
      seq = sequence("reverse")
      first_mock_action = rescueable_mock("first")
      second_mock_action = rescueable_mock("second")

      @instance.stack = [first_mock_action, second_mock_action]

      second_mock_action.expects(:rescue).in_sequence(seq)
      first_mock_action.expects(:rescue).in_sequence(seq)

      @instance.begin_rescue(new_env)
    end

    should "call error and exit" do
      @instance.expects(:error_and_exit)
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
    mock_action.stubs(:respond_to?).with(:rescue).returns(true)
    mock_action
  end
end
