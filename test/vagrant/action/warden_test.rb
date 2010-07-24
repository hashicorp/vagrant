require "test_helper"

class ActionWardenTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Warden
    @instance = @klass.new([], {})
  end

  context "initializing" do
    should "finalize the middleware" do
      middleware = [1,2,3]
      middleware.each do |m|
        @klass.any_instance.expects(:finalize_action).with(m, {}).returns(m)
      end
      @warden = @klass.new(middleware, {})
      assert_equal @warden.actions, [3,2,1]
    end
  end

  context "setting up middleware" do
    should "make non-classes lambdas" do
      env = Vagrant::Action::Environment.new(nil)
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
      assert !@instance.call({})
    end

    should "move the last action to the front of the stack" do
      @instance.actions << lambda {}
      assert @instance.stack.empty?
      @instance.call({})
      assert !@instance.stack.empty?
      assert @instance.actions.empty?
    end

    should "call the next action" do
      action = mock('action')
      action.expects(:call).with({})
      @instance.actions << action
      @instance.call({})
    end
  end
end
