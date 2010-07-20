require "test_helper"

class CommandsProvisionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Provision
    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "provision all if no name is given" do
      @instance.expects(:all_or_single).with([], :provision).once
      @instance.execute
    end
  end

  context "provisioning a single VM" do
    setup do
      @foo_vm = mock("vm")
      @foo_vm.stubs(:env).returns(@env)
      @foo_vm.stubs(:created?).returns(true)

      @vm_for_real = mock("vm for real")
      @foo_vm.stubs(:vm).returns(@vm_for_real)
      vms = { :foo => @foo_vm }
      @env.stubs(:vms).returns(vms)
    end

    should "error and exit if the VM doesn't exist" do
      @env.stubs(:vms).returns({})
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => 'foo').once
      @instance.execute(["foo"])
    end

    should "reload if it's running" do
      @vm_for_real.stubs(:running?).returns(true)
      @foo_vm.expects(:provision).once
      @instance.execute(["foo"])
    end

    should "do log to info if it's not running" do
      logger = mock("logger")
      logger.expects(:info)
      @env.stubs(:logger).returns(logger)
      @vm_for_real.stubs(:running?).returns(false)
      @foo_vm.expects(:provision).never
      @instance.execute(["foo"])
    end

    should "do log to info if it's not created" do
      logger = mock("logger")
      logger.expects(:info)
      @env.stubs(:logger).returns(logger)
      @foo_vm.stubs(:created?).returns(false)
      @foo_vm.expects(:provision).never
      @instance.execute(["foo"])
    end
  end

end
