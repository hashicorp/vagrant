require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class StopActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Stop)
  end

  should "force the VM to stop" do
    @vm.expects(:stop).with(true).once
    @action.execute!
  end
end
