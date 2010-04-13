require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsDestroyTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Destroy

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @persisted_vm.stubs(:destroy)
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      @instance.execute
    end

    should "destroy the persisted VM and the VM image" do
      @persisted_vm.expects(:destroy).once
      @instance.execute
    end
  end
end
