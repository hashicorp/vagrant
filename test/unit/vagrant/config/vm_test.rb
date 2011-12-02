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

    should "use static ip for host-only interface when given" do
      @config.network "1.1.1.1"

      assert_equal "1.1.1.1", @config.network_options[1][:ip]
      assert !@config.network_options[1][:dhcp]
    end

    should "use dynamic ip for host-only interface when specifying DHCP" do
      @config.network "1.1.1.1", :dhcp => true

      assert_equal "1.1.1.1", @config.network_options[1][:ip]
      assert @config.network_options[1][:dhcp]
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
end
