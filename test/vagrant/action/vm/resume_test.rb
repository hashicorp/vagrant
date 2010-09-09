require "test_helper"

class ResumeVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Resume
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "run the proper methods when saved" do
      @internal_vm.expects(:saved?).returns(true)

      seq = sequence("seq")
      @env.env.actions.expects(:run).with(Vagrant::Action::VM::Boot).once.in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)
      @instance.call(@env)
    end

    should "do nothing if VM is not saved" do
      @internal_vm.expects(:saved?).returns(false)

      @vm.expects(:start).never
      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end
end
