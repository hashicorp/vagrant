require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase

  context "Hobo configuration" do
    setup do
      @settings = {:a => { :b => 1}}
      Hobo.set_config!(@settings)
    end

    should "prevent alteration after initial creation" do
      assert_raise TypeError do
        Hobo.config[:a] = 1
      end
    end

    should "leave the actual config unaltered when changing the alterable version" do
      Hobo.alterable_config[:a] = 1
      assert_equal Hobo.config, @settings
    end

    should "ensure that the alterable config and config match initially" do
      assert_equal Hobo.config, Hobo.alterable_config
    end

    # TODO of debatable usefulness this test is 
    should "allow for the alteration of the config" do
      Hobo.alterable_config[:a] = 1
      assert_not_equal Hobo.alterable_config, Hobo.config
    end
  end
end
