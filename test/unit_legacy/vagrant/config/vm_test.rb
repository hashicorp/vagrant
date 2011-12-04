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
end
