require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsUpTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Up

    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "call up_all if no name is given" do
      @instance.expects(:up_all).once
      @instance.execute
    end

    should "call up_single if a name is given" do
      @instance.expects(:up_single).with("foo").once
      @instance.execute(["foo"])
    end
  end

  context "upping a single VM" do
    setup do
      @vm = mock("vm")
      @vm.stubs(:env).returns(@env)

      @vms = {:foo => @vm}
      @env.stubs(:vms).returns(@vms)
    end

    should "error and exit if the VM doesn't exist" do
      @env.stubs(:vms).returns({})
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.up_single(:foo)
    end

    should "start created VMs" do
      @vm.stubs(:created?).returns(true)
      @vm.expects(:start).once
      @instance.up_single(:foo)
    end

    should "up non-created VMs" do
      @vm.stubs(:created?).returns(false)
      @vm.env.expects(:require_box).once
      @vm.expects(:up).once
      @vm.expects(:start).never
      @instance.up_single(:foo)
    end
  end

  context "upping all VMs" do
    setup do
      @vms = {}
      @env.stubs(:vms).returns(@vms)
    end

    def create_vm
      vm = mock("vm")
      vm.stubs(:env).returns(mock_environment)
      vm.stubs(:created?).returns(false)
      vm
    end

    should "require a box for all VMs" do
      @vms[:foo] = create_vm
      @vms[:bar] = create_vm

      @vms.each do |name, vm|
        vm.env.expects(:require_box).once
        @instance.expects(:up_single).with(name).once
      end

      @instance.up_all
    end
  end
end
