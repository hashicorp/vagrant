require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class BaseProvisionerTest < Test::Unit::TestCase
  should "include the util class so subclasses have access to it" do
    assert Vagrant::Provisioners::Base.include?(Vagrant::Util)
  end

  context "base instance" do
    setup do
      @env = mock_environment
      @base = Vagrant::Provisioners::Base.new(@env)
    end

    should "set the environment" do
      base = Vagrant::Provisioners::Base.new(@env)
      assert_equal @env, base.env
    end

    should "implement provision! which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:provision!)
        @base.provision!
      end
    end

    should "implement prepare which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:prepare)
        @base.prepare
      end
    end
  end
end
