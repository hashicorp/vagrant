require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsUpTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Up

    @env = mock_environment
    @instance = @klass.new(@env)

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)
  end

  context "executing" do
    setup do
      @new_vm = mock("vm")
      @new_vm.stubs(:execute!)

      @env.stubs(:vm).returns(nil)
      @env.stubs(:require_box)
      @env.stubs(:create_vm).returns(@new_vm)
    end

    should "require a box" do
      @env.expects(:require_box).once
      @instance.execute
    end

    should "call the up action on VM if it doesn't exist" do
      @new_vm.expects(:execute!).with(Vagrant::Actions::VM::Up).once
      @instance.execute
    end

    should "call start on the persisted vm if it exists" do
      @env.stubs(:vm).returns(@persisted_vm)
      @persisted_vm.expects(:start).once
      @env.expects(:create_vm).never
      @instance.execute
    end
  end
end
