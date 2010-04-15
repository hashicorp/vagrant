require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BusyTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Busy
  end

  context "waiting for not busy" do
    setup do
      @klass.reset_trap_thread!
    end

    should "run in a thread" do
      Thread.expects(:new).once.returns(nil)
      @klass.wait_for_not_busy
    end

    should "immediately exit on second call" do
      tid = "foo"
      Thread.expects(:new).once.returns(tid)
      @klass.wait_for_not_busy

      Thread.expects(:kill).once.with(tid)
      @klass.expects(:abort).once
      @klass.wait_for_not_busy
    end
  end

  context "during an action in a busy block" do
    should "report as busy" do
      Vagrant.busy do
        # Inside the block Vagrant.busy? should be true
        assert Vagrant.busy?
      end

      #After the block finishes Vagrant.busy? should be false
      assert !Vagrant.busy?
    end

    should "set busy to false upon exception and reraise the error" do
      assert_raise Exception do
        Vagrant.busy do
          assert Vagrant.busy?
          raise Exception
        end
      end

      assert !Vagrant.busy?
    end

    should "complete the trap thread even if an exception occurs" do
      trap_thread = mock("trap_thread")
      trap_thread.expects(:join).once
      @klass.stubs(:trap_thread).returns(trap_thread)

      assert_raise Exception do
        Vagrant.busy do
          raise Exception
        end
      end
    end

    should "report busy to the outside world regardless of thread" do
      Thread.new do
        Vagrant.busy do
          sleep(2)
        end
      end
      # Give the thread time to start
      sleep(1)

      # While the above thread is executing vagrant should be busy
      assert Vagrant.busy?
    end

    should "run the action in a new thread" do
      runner_thread = nil
      Vagrant.busy do
        runner_thread = Thread.current
      end

      assert_not_equal Thread.current, runner_thread
    end

    should "trap INT" do
      trap_seq = sequence("trap_seq")
      Signal.expects(:trap).with("INT", anything).once.in_sequence(trap_seq)
      Signal.expects(:trap).with("INT", "DEFAULT").once.in_sequence(trap_seq)
      Vagrant.busy do; end
    end
  end
end
