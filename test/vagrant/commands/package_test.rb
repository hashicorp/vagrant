require "test_helper"

class CommandsPackageTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Package

    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "package base if a base is given" do
      @instance.expects(:package_base).once
      @instance.execute(["--base","foo"])
    end

    should "package single if no name is given" do
      @instance.expects(:package_single).with(nil).once
      @instance.execute
    end

    should "package single if a name is given" do
      @instance.expects(:package_single).with("foo").once
      @instance.execute(["foo"])
    end
  end

  context "packaging base" do
    should "error and exit if no VM is found" do
      Vagrant::VM.expects(:find).with("foo", @instance.env).returns(nil)
      @instance.expects(:error_and_exit).with(:vm_base_not_found, :name => "foo").once
      @instance.execute(["--base", "foo"])
    end

    should "package the VM like any other VM" do
      vm = mock("vm")
      Vagrant::VM.expects(:find).with("foo", @instance.env).returns(vm)
      @instance.expects(:package_vm).with(vm).once
      @instance.execute(["--base", "foo"])
    end
  end

  context "packaging a single VM" do
    setup do
      @vm = mock("vm")
      @vm.stubs(:created?).returns(true)

      @vms = {:bar => @vm}
      @env.stubs(:vms).returns(@vms)
      @env.stubs(:multivm?).returns(false)
    end

    should "error and exit if no name is given in a multi-vm env" do
      @env.stubs(:multivm?).returns(true)
      @instance.expects(:error_and_exit).with(:package_multivm).once
      @instance.package_single(nil)
    end

    should "error and exit if the VM doesn't exist" do
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.package_single(:foo)
    end

    should "error and exit if the VM is not created" do
      @vm.stubs(:created?).returns(false)
      @instance.expects(:error_and_exit).with(:environment_not_created).once
      @instance.package_single(:bar)
    end

    should "use the first VM is no name is given in a single VM environment" do
      @instance.expects(:package_vm).with(@vm).once
      @instance.package_single(nil)
    end

    should "package the VM" do
      @instance.expects(:package_vm).with(@vm).once
      @instance.package_single(:bar)
    end
  end

  context "packaging a VM" do
    setup do
      @vm = mock("vm")

      @options = {}
      @instance.stubs(:options).returns(@options)
    end

    should "package the VM with the proper arguments" do
      @options[:output] = "foo.box"
      @options[:include] = :bar

      @vm.expects(:package).with(@options).once
      @instance.package_vm(@vm)
    end
  end
end
