require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsHaltTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Halt

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      @instance.execute
    end

    should "call the `halt` action on the VM" do
      @persisted_vm.expects(:execute!).with(Vagrant::Actions::VM::Halt).once
      @instance.execute
    end
  end
end
