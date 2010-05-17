require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class BaseProvisionerTest < Test::Unit::TestCase
  should "include the util class so subclasses have access to it" do
    assert Vagrant::Provisioners::Base.include?(Vagrant::Util)
  end

  context "base instance" do
    setup do
      @vm = mock("vm")
      @base = Vagrant::Provisioners::Base.new(@vm)
    end

    should "set the environment" do
      base = Vagrant::Provisioners::Base.new(@vm)
      assert_equal @vm, base.vm
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
