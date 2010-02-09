require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BusyTest < Test::Unit::TestCase
  context "during an action in a busy block" do
    should "hobo should report as busy" do
      Hobo.busy do
        # Inside the block Hobo.busy? should be true
        assert Hobo.busy?
      end

      #After the block finishes Hobo.busy? should be false
      assert !Hobo.busy? 
    end
    
    should "set busy to false upon exception and reraise the error" do
      assert_raise Exception do
        Hobo.busy do
          assert Hobo.busy?
          raise Exception
        end
      end
      
      assert !Hobo.busy?
    end

    should "report busy to the outside world regardless of thread" do
      Thread.new do
        Hobo.busy do
          sleep(10)
        end
      end
      
      # While the above thread is executing hobo should be busy
      assert Hobo.busy?
    end
  end
end
