require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BusyTest < Test::Unit::TestCase
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

    should "report busy to the outside world regardless of thread" do
      Thread.new do
        Vagrant.busy do
          sleep(1)
        end
      end

      # While the above thread is executing vagrant should be busy
      assert Vagrant.busy?
    end
  end
end
