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
        action = [action] unless action.is_a?(Array)
        @runner.expects(:add_action).with(action.shift, *action).once.in_sequence(default_seq)
      end
    end

    should "add the destroy action alone if VM is not running" do
      setup_action_expectations([Vagrant::Actions::VM::Destroy])
      @action.prepare
    end

    should "add the halt action if the VM is running" do
      @vm.expects(:running?).returns(true)
      setup_action_expectations([[Vagrant::Actions::VM::Halt, {:force => true}], Vagrant::Actions::VM::Destroy])
      @action.prepare
    end
  end

  context "after halting" do
    should "sleep" do
      Kernel.expects(:sleep).once
      @action.after_halt
    end
  end
end
