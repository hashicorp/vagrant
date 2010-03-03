require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class HaltActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Halt)
    mock_config
  end

  context "executing" do
    should "force the VM to stop" do
      @vm.expects(:stop).with(true).once
      @action.execute!
    end
  end
end
