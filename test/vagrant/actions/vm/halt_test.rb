require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class HaltActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Halt)
  end

  context "executing" do
    setup do
      @vm.stubs(:running?).returns(true)
    end

    should "invoke the 'halt' around callback" do
      halt_seq = sequence("halt_seq")
      @runner.expects(:invoke_around_callback).with(:halt).once.in_sequence(halt_seq).yields
      @vm.expects(:stop).in_sequence(halt_seq)
      @action.execute!
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
