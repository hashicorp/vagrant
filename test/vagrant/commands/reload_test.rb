require "test_helper"

class CommandsReloadTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Reload

    @env = mock_environment
    @env.stubs(:require_root_path)
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "call all or single for the method" do
      seq = sequence("seq")
      @env.expects(:require_root_path).in_sequence(seq)
      @instance.expects(:all_or_single).with([], :reload).in_sequence(seq)
      @instance.execute
    end
  end

  context "reloading a single VM" do
    setup do
      @foo_vm = mock("vm")
      @foo_vm.stubs(:env).returns(@env)
      vms = { :foo => @foo_vm }
      @env.stubs(:vms).returns(vms)
    end

    should "error and exit if the VM doesn't exist" do
      @env.stubs(:vms).returns({})
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.reload_single(:foo)
    end

    should "reload if its created" do
      @foo_vm.stubs(:created?).returns(true)
      @foo_vm.expects(:reload).once
      @instance.execute(["foo"])
    end

    should "do nothing if its not created" do
      @foo_vm.stubs(:created?).returns(false)
      @foo_vm.expects(:reload).never
      @instance.reload_single(:foo)
    end
  end
end
