require "test_helper"

class BaseDownloaderTest < Test::Unit::TestCase
  should "include the util class so subclasses have access to it" do
    assert Vagrant::Downloaders::Base.include?(Vagrant::Util)
  end

  context "base instance" do
    setup do
      @env = vagrant_env
      @base = Vagrant::Downloaders::Base.new(@env)
    end

    should "implement prepare which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:prepare)
        @base.prepare("source")
      end
    end

    should "implement download! which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:download!)
        @base.download!("source", "destination")
      end
    end
  end
end
