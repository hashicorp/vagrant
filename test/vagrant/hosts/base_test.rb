require "test_helper"

class BaseHostTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Hosts::Base
  end

  context "class methods" do
    context "loading" do
      setup do
        @env = vagrant_env
      end

      should "return detected class if klass is nil" do
        Vagrant::Util::Platform.stubs(:platform).returns("darwin")
        result = @klass.load(@env, nil)
        assert result.is_a?(Vagrant::Hosts::BSD)
      end

      should "instantiate the given class" do
        result = @klass.load(@env, Vagrant::Hosts::BSD)
        assert result.is_a?(Vagrant::Hosts::BSD)
        assert_equal @env, result.env
      end
    end

    context "detecting class" do
      should "return the proper class" do
        Vagrant::Util::Platform.stubs(:platform).returns("darwin10")
        assert_equal Vagrant::Hosts::BSD, @klass.detect
      end

      should "return nil if no class is detected" do
        Vagrant::Util::Platform.stubs(:platform).returns("boo")
        assert_nil @klass.detect
      end

      should "return nil if an exception is raised" do
        Vagrant::Util::Platform.stubs(:platform).returns("boo")
        assert_nothing_raised {
          assert_nil @klass.detect
        }
      end
    end
  end
end
