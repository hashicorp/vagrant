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

      @vms = {}

      @env.stubs(:vms).returns(@vms)
      @env.stubs(:require_box)
    end

    def create_vm
      env = mock_environment
      env.stubs(:require_box)

      vm = mock("vm")
      vm.stubs(:env).returns(env)
      vm.stubs(:execute!)
      vm.stubs(:created?).returns(false)
      vm
    end

    should "require a box for all VMs" do
      @vms[:foo] = create_vm
      @vms[:bar] = create_vm

      @vms.each do |name, vm|
        vm.env.expects(:require_box).once
      end

      @instance.execute
    end

    should "start created VMs" do
      vm = create_vm
      vm.stubs(:created?).returns(true)

      @vms[:foo] = vm

      vm.expects(:start).once
      @instance.execute
    end

    should "up non-created VMs" do
      vm = create_vm
      vm.expects(:execute!).with(Vagrant::Actions::VM::Up).once
      vm.expects(:start).never

      @vms[:foo] = vm
      @instance.execute
    end
  end
end
