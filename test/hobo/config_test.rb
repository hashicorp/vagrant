require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase
  context "Hobo configuration" do
    setup do
      @settings = {:a => { :b => 1}}
      Hobo.config!(@settings)
    end

    should "alter the config given a dot chain of keys" do
      Hobo.set_config_value 'a.b', 2
      assert_equal Hobo.config[:a][:b], 2
    end

    should "prevent the alteration of a non leaf setting value" do
      assert_raise Hobo::InvalidSettingAlteration do
        Hobo.set_config_value 'a', 2
      end
    end

    should "not alter settings through the chain method when provided and empty string" do
      prev = Hobo.config
      Hobo.set_config_value '', 2
      assert_equal Hobo.config, prev
    end
  end
end
