require "test_helper"

class HostNameVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::HostName
    @app, @env = action_env
    @instance = @klass.new(@app, @env)

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  should "not run anything if no host name is set" do
    @env["config"].vm.host_name = nil
    @env["vm"].expects(:system).never
    @app.expects(:call).with(@env).once

    @instance.call(@env)
  end

  should "change host name if set" do
    @env["config"].vm.host_name = "foo"

    system = mock("system")
    @vm.stubs(:system).returns(system)

    seq = sequence("host_seq")
    @app.expects(:call).with(@env).in_sequence(seq)
    system.expects(:change_host_name).with(@env["config"].vm.host_name).in_sequence(seq)

    @instance.call(@env)
  end
end
