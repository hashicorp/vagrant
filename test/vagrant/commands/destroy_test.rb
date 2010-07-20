require "test_helper"

class CommandsDestroyTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Destroy

    @env = mock_environment

    @instance = @klass.new(@env)
  end

  context "executing" do
    should "call all or single for the method" do
      @instance.expects(:all_or_single).with([], :destroy)
      @instance.execute
    end
  end

  context "destroying a single VM" do
    setup do
      @foo_vm = mock("vm")
      @foo_vm.stubs(:env).returns(@env)
      vms = { :foo => @foo_vm }
      @env.stubs(:vms).returns(vms)
    end
    should "error and exit if the VM doesn't exist" do
      @env.stubs(:vms).returns({})
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.destroy_single(:foo)
    end

    should "destroy if its created" do
      @foo_vm.stubs(:created?).returns(true)
      @foo_vm.expects(:destroy).once
      @instance.destroy_single(:foo)
    end

    should "do nothing if its not created" do
      @foo_vm.stubs(:created?).returns(false)
      @foo_vm.expects(:destroy).never
      @instance.destroy_single(:foo)
    end
  end
end
