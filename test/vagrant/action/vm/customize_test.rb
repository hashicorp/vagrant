require "test_helper"

class CustomizeVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Customize
    @app, @env = action_env
    @instance = @klass.new(@app, @env)

    @vm = mock("vm")
    @env["vm"] = @vm
    @env["vm.modify"] = mock("proc")

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  should "not run anything if no customize blocks exist" do
    @env["config"].vm.proc_stack.clear
    @env["vm.modify"].expects(:call).never
    @app.expects(:call).with(@env).once
    @instance.call(@env)
  end

  should "run the VM customization procs then save the VM" do
    ran = false
    @env["config"].vm.customize { |vm| }
    @env["config"].vm.expects(:run_procs!).with(@internal_vm)

    @env["vm.modify"].expects(:call).with() do |proc|
      proc.call(@internal_vm)
      true
    end

    @app.expects(:call).with(@env).once
    @instance.call(@env)
  end
end
