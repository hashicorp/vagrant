require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsPackageTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Package

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @persisted_vm.stubs(:package)
      @persisted_vm.stubs(:powered_off?).returns(true)
    end

    context "with no base specified" do
      should "require a persisted vm" do
        @env.expects(:require_persisted_vm).once
        @instance.execute
      end
    end

    context "with base specified" do
      setup do
        @vm = mock("vm")

        Vagrant::VM.stubs(:find).with(@name).returns(@vm)
        @vm.stubs(:env=).with(@env)
        @env.stubs(:vm=)

        @name = "bar"
      end

      should "find the given base and set it on the env" do
        Vagrant::VM.expects(:find).with(@name).returns(@vm)
        @vm.expects(:env=).with(@env)
        @env.expects(:vm=).with(@vm)

        @instance.execute(["foo", "--base", @name])
      end

      should "error if the VM is not found" do
        Vagrant::VM.expects(:find).with(@name).returns(nil)
        @instance.expects(:error_and_exit).with(:vm_base_not_found, :name => @name).once

        @instance.execute(["foo", "--base", @name])
      end
    end

    context "shared (with and without base specified)" do
      should "error and exit if the VM is not powered off" do
        @persisted_vm.stubs(:powered_off?).returns(false)
        @instance.expects(:error_and_exit).with(:vm_power_off_to_package).once
        @persisted_vm.expects(:package).never
        @instance.execute
      end

      should "call package on the persisted VM" do
        @persisted_vm.expects(:package).once
        @instance.execute
      end

      should "pass the out path and include_files to the package method" do
        out_path = mock("out_path")
        include_files = "foo"
        @persisted_vm.expects(:package).with(out_path, [include_files]).once
        @instance.execute([out_path, "--include", include_files])
      end

      should "default to an empty array when not include_files are specified" do
        out_path = mock("out_path")
        @persisted_vm.expects(:package).with(out_path, []).once
        @instance.execute([out_path])
      end
    end
  end
end
