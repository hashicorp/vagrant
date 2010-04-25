require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class HaltActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Halt)
    @runner.stubs(:system).returns(linux_system(@vm))
  end

  context "executing" do
    setup do
      @vm.stubs(:running?).returns(true)

      @runner.system.stubs(:halt)
      @vm.stubs(:stop)
      @vm.stubs(:state).returns(:powered_off)
    end

    should "invoke the 'halt' around callback" do
      @runner.expects(:invoke_around_callback).with(:halt).once
      @action.execute!
    end

    should "halt with the system and NOT force VM to stop if powered off" do
      @vm.expects(:state).with(true).returns(:powered_off)

      @runner.system.expects(:halt).once
      @vm.expects(:stop).never
      @action.execute!
    end

    should "halt with the system and force VM to stop if NOT powered off" do
      @vm.expects(:state).with(true).returns(:running)

      @runner.system.expects(:halt).once
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
