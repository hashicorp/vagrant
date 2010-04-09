require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ReloadActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Reload)
  end

  context "sub-actions" do
    setup do
      @default_order = [Vagrant::Actions::VM::Customize, Vagrant::Actions::VM::ForwardPorts, Vagrant::Actions::VM::SharedFolders, Vagrant::Actions::VM::Boot]
      @vm.stubs(:running?).returns(false)
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @runner.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "halt if the VM is running" do
      @vm.expects(:running?).returns(true)
      @default_order.unshift(Vagrant::Actions::VM::Halt)
      setup_action_expectations
      @action.prepare
    end

    should "add in the provisioning step if enabled" do
      env = mock_environment do |config|
        # Dummy provisioner to test
        config.vm.provisioner = "foo"
      end

      @runner.stubs(:env).returns(env)

      @default_order.push(Vagrant::Actions::VM::Provision)
      setup_action_expectations
      @action.prepare
    end
  end
end
