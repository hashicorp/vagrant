require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CustomizeVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Customize
    @app, @env = mock_action_data
    @instance = @klass.new(@app, @env)

    @vm = mock("vm")
    @env["vm"] = @vm
  end

  should "not run anything if no customize blocks exist" do
    @vm.expects(:save).never
    @app.expects(:call).with(@env).once
    @instance.call(@env)
  end

  should "run the VM customization procs then save the VM" do
    @env.env.config.vm.customize { |vm| }
    @env.env.config.vm.expects(:run_procs!).with(@vm)
    @vm.expects(:save).once
    @app.expects(:call).with(@env).once
    @instance.call(@env)
  end
end
