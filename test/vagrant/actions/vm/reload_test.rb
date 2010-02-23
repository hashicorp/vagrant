require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ReloadActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Reload)
    mock_config
  end

  context "sub-actions" do
    setup do
      @default_order = [Vagrant::Actions::VM::Stop, Vagrant::Actions::VM::ForwardPorts, Vagrant::Actions::VM::SharedFolders, Vagrant::Actions::VM::Start]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @mock_vm.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "add in the provisioning step if enabled" do
      mock_config do |config|
        config.chef.enabled = true
      end

      @default_order.push(Vagrant::Actions::VM::Provision)
      setup_action_expectations
      @action.prepare
    end
  end
end
