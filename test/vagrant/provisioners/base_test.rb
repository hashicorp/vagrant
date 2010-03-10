require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class BaseProvisionerTest < Test::Unit::TestCase
  should "include the util class so subclasses have access to it" do
    assert Vagrant::Provisioners::Base.include?(Vagrant::Util)
  end

  context "base instance" do
    setup do
      @base = Vagrant::Provisioners::Base.new
    end

    should "implement provision! which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:provision!)
        @base.provision!
      end
    end
  end
end
