require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DownActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Down)
  end

  context "preparing" do
    setup do
      @vm.stubs(:running?).returns(false)
    end

    def setup_action_expectations(order)
      default_seq = sequence("default_seq")
      order.each do |action|
        @runner.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "add the destroy action alone if VM is not running" do
      setup_action_expectations([Vagrant::Actions::VM::Destroy])
      @action.prepare
    end

    should "add the halt action if the VM is running" do
      @vm.expects(:running?).returns(true)
      setup_action_expectations([Vagrant::Actions::VM::Halt, Vagrant::Actions::VM::Destroy])
      @action.prepare
    end
  end

  context "after halting" do
    should "sleep if boot mode is GUI" do
      @runner.env.config.vm.boot_mode = "gui"
      Kernel.expects(:sleep).once
      @action.after_halt
    end

    should "not sleep if boot mode is anything else" do
      @runner.env.config.vm.boot_mode = "vrdp"
      Kernel.expects(:sleep).never
      @action.after_halt
    end
  end
end
