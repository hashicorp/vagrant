require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class SuspendActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Suspend)
  end

  context "executing" do
    setup do
      @vm.stubs(:running?).returns(true)
    end

    should "save the state of the VM" do
      @vm.expects(:save_state).once
      @action.execute!
    end

    should "raise an ActionException if the VM is not running" do
      @vm.expects(:running?).returns(false)
      @vm.expects(:save_state).never
      assert_raises(Vagrant::Actions::ActionException) {
        @action.execute!
      }
    end
  end
end
