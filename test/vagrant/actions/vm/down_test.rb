require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DownActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Down)
    mock_config
  end

  context "preparing" do
    setup do
      @vm.stubs(:running?).returns(false)
    end

    def setup_action_expectations(order)
      default_seq = sequence("default_seq")
      order.each do |action|
        @mock_vm.expects(:add_action).with(action).once.in_sequence(default_seq)
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
end
