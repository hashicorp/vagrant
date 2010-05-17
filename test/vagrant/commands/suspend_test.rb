require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsSuspendTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Suspend

    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "call on all if no name is given" do
      @instance.expects(:suspend_all).once
      @instance.execute
    end

    should "call on single if a name is given" do
      @instance.expects(:suspend_single).with("foo").once
      @instance.execute(["foo"])
    end
  end

  context "suspending all" do
    should "suspend each VM" do
      vms = { :foo => nil, :bar => nil, :baz => nil }
      @env.stubs(:vms).returns(vms)

      vms.each do |name, value|
        @instance.expects(:suspend_single).with(name).once
      end

      @instance.suspend_all
    end
  end

  context "suspending a single VM" do
    setup do
      @foo_vm = mock("vm")
      vms = { :foo => @foo_vm }
      @env.stubs(:vms).returns(vms)
    end

    should "error and exit if the VM doesn't exist" do
      @env.stubs(:vms).returns({})
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.suspend_single(:foo)
    end

    should "halt if its created" do
      @foo_vm.stubs(:created?).returns(true)
      @foo_vm.expects(:suspend).once
      @instance.execute(["foo"])
    end

    should "halt and force if specified" do
      @foo_vm.stubs(:created?).returns(true)
      @foo_vm.expects(:suspend).once
      @instance.execute(["foo"])
    end

    should "do nothing if its not created" do
      @foo_vm.stubs(:created?).returns(false)
      @foo_vm.expects(:suspend).never
      @instance.suspend_single(:foo)
    end
  end
end
