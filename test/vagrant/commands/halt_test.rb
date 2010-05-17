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
    should "call halt_all if no name is given" do
      @instance.expects(:halt_all).once
      @instance.execute
    end

    should "call halt_single if a name is given" do
      @instance.expects(:halt_single).with("foo").once
      @instance.execute(["foo"])
    end
  end

  context "halting all" do
    should "halt each VM" do
      vms = { :foo => nil, :bar => nil, :baz => nil }
      @env.stubs(:vms).returns(vms)

      vms.each do |name, value|
        @instance.expects(:halt_single).with(name).once
      end

      @instance.halt_all
    end
  end

  context "halting a single VM" do
    setup do
      @foo_vm = mock("vm")
      vms = { :foo => @foo_vm }
      @env.stubs(:vms).returns(vms)
    end

    should "error and exit if the VM doesn't exist" do
      @env.stubs(:vms).returns({})
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.halt_single(:foo)
    end

    should "halt if its created" do
      @foo_vm.stubs(:created?).returns(true)
      @foo_vm.expects(:halt).with(false).once
      @instance.execute(["foo"])
    end

    should "halt and force if specified" do
      @foo_vm.stubs(:created?).returns(true)
      @foo_vm.expects(:halt).with(true).once
      @instance.execute(["foo", "--force"])
    end

    should "do nothing if its not created" do
      @foo_vm.stubs(:created?).returns(false)
      @foo_vm.expects(:halt).never
      @instance.halt_single(:foo)
    end
  end
end
