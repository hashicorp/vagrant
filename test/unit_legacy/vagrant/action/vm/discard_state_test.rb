require "test_helper"

class DiscardStateVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::DiscardState
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      @vm.stubs(:created?).returns(true)
      @internal_vm.stubs(:saved?).returns(false)
    end

    should "do nothing if the VM is not created" do
      @vm.stubs(:created?).returns(false)
      @internal_vm.expects(:discard_state).never
      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end

    should "do nothing if not saved and continue chain" do
      @internal_vm.expects(:saved?).returns(false)
      @internal_vm.expects(:discard_state).never
      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end

    should "discard state and continue chain" do
      seq = sequence("sequence")
      @internal_vm.expects(:saved?).returns(true).in_sequence(seq)
      @internal_vm.expects(:discard_state).in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)
      @instance.call(@env)
    end
  end
end
