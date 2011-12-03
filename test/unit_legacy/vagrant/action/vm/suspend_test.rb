require "test_helper"

class SuspendVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Suspend
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "run the proper methods when running" do
      @internal_vm.expects(:running?).returns(true)

      seq = sequence("seq")
      @internal_vm.expects(:save_state).once.in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)
      @instance.call(@env)
    end

    should "do nothing if VM is not running" do
      @internal_vm.expects(:running?).returns(false)

      @internal_vm.expects(:save_state).never
      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end
end
