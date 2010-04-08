require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class HaltActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Halt)
    mock_config
  end

  context "executing" do
    setup do
      @vm.stubs(:running?).returns(true)
    end

    should "force the VM to stop" do
      @vm.expects(:stop).once
      @action.execute!
    end

    should "raise an ActionException if VM is not running" do
      @vm.stubs(:running?).returns(false)
      @vm.expects(:stop).never
      assert_raises(Vagrant::Actions::ActionException) {
        @action.execute!
      }
    end
  end
end
