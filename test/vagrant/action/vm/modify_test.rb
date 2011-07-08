require "test_helper"

class ModifyVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Modify
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "initialization" do
    should "have the vm.modify function setup in the environment" do
      assert @env.has_key?("vm.modify")
    end
  end

  context "calling" do
    should "run the procs with the VM as an argument and save the VM" do
      seq = sequence("procseq")

      proc = Proc.new { |vm| }
      @env["vm.modify"].call(proc)

      proc.expects(:call).with(@internal_vm).once.in_sequence(seq)
      @internal_vm.expects(:save).once.in_sequence(seq)
      @vm.expects(:reload!).once.in_sequence(seq)

      @instance.call(@env)
    end
  end
end
