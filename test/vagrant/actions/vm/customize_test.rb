require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CustomizeActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Customize)
  end

  context "executing" do
    should "run the VM customization procs then save the VM" do
      @runner.env.config.vm.expects(:run_procs!).with(@vm)
      @vm.expects(:save).once
      @action.execute!
    end
  end
end
