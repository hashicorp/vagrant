require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class StartActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Start)
  end

  context "sub-actions" do
    setup do
      @vm.stubs(:saved?).returns(true)
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @default_order = [Vagrant::Actions::VM::Boot]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.flatten.each do |action|
        @mock_vm.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "add customize to the beginning if its not saved" do
      @vm.expects(:saved?).returns(false)
      @default_order.unshift([Vagrant::Actions::VM::Customize, Vagrant::Actions::VM::ForwardPorts, Vagrant::Actions::VM::SharedFolders])
      setup_action_expectations
      @action.prepare
    end
  end
end
