require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsResumeTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Resume

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @persisted_vm.stubs(:resume)
      @persisted_vm.stubs(:saved?).returns(true)
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      @instance.execute
    end

    should "save the state of the VM" do
      @persisted_vm.expects(:resume).once
      @instance.execute
    end
  end
end
