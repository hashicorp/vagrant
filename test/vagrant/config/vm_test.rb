require "test_helper"

class ConfigVMTest < Test::Unit::TestCase
  setup do
    @username = "mitchellh"

    @env = vagrant_env
    @config = @env.config.vm
    @env.config.ssh.username = @username
  end

  context "defining VMs" do
    should "store the proc by name but not run it" do
      foo = mock("proc")
      foo.expects(:call).never

      proc = Proc.new { foo.call }
      @config.define(:name, &proc)
      assert @config.defined_vms[:name].proc_stack.include?(proc)
    end

    should "store the options" do
      @config.define(:name, :set => true)
      assert @config.defined_vms[:name].options[:set]
    end

    should "not have multi-VMs by default" do
      assert !@config.has_multi_vms?
    end

    should "have multi-VMs once one is specified" do
      @config.define(:foo) {}
      assert @config.has_multi_vms?
    end

    should "retain vm definition order" do
      @config.define(:a) {}
      @config.define(:b) {}
      @config.define(:c) {}

      assert_equal [:a, :b, :c], @config.defined_vm_keys
    end
  end

  context "customizing" do
    should "include the stacked proc runner module" do
      assert @config.class.included_modules.include?(Vagrant::Util::StackedProcRunner)
    end

    should "add the customize proc to the proc stack" do
      proc = Proc.new {}
      @config.customize(&proc)
      assert @config.proc_stack.include?(proc)
    end
  end

  context "uid/gid" do
    should "return the shared folder UID if set" do
      @config.shared_folder_uid = "foo"
      assert_equal "foo", @config.shared_folder_uid
    end

    should "return the SSH username if UID not set" do
      @config.shared_folder_uid = nil
      assert_equal @username, @config.shared_folder_uid
    end

    should "return the shared folder GID if set" do
      @config.shared_folder_gid = "foo"
      assert_equal "foo", @config.shared_folder_gid
    end

    should "return the SSH username if GID not set" do
      @config.shared_folder_gid = nil
      assert_equal @username, @config.shared_folder_gid
    end
  end

  context "deprecated config" do
    should "raise an error for provisioner=" do
      assert_raises(Vagrant::Errors::VagrantError) {
        @config.provisioner = :chef_solo
      }
    end
  end
end
