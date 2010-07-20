require "test_helper"

class DestroyVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Destroy
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "destroying the VM" do
    should "destroy VM and attached images" do
      @internal_vm.expects(:destroy).with(:destroy_medium => :delete).once
      @env["vm"].expects(:vm=).with(nil).once
      @env.env.expects(:update_dotfile).once
      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end
end
