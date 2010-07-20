require "test_helper"

class CommandsStatusTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Status

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    should "show local status by default" do
      @instance.expects(:show_local_status).once
      @instance.expects(:show_global_status).never
      @instance.execute
    end

    should "show global status if flagged" do
      @instance.expects(:show_local_status).never
      @instance.expects(:show_global_status).once
      @instance.execute(["--global"])
    end

    should "show help if too many args are given" do
      @instance.expects(:show_help).once
      @instance.execute(["1","2","3"])
    end

    should "pass the VM name to local status if given" do
      @instance.expects(:show_local_status).with("foo").once
      @instance.execute(["foo"])
    end
  end
end
