require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase
  context "accessing configuration" do
    setup do
      Hobo::Config.run { |config| }
      Hobo::Config.execute!
    end

    should "forward config to the class method" do
      assert_equal Hobo.config, Hobo::Config.config
    end
  end

  context "initializing" do
    teardown do
      Hobo::Config.instance_variable_set(:@config_runners, nil)
      Hobo::Config.instance_variable_set(:@config, nil)
    end

    should "not run the blocks right away" do
      obj = mock("obj")
      obj.expects(:foo).never
      Hobo::Config.run { |config| obj.foo }
      Hobo::Config.run { |config| obj.foo }
      Hobo::Config.run { |config| obj.foo }
    end

    should "run the blocks when execute! is ran" do
      obj = mock("obj")
      obj.expects(:foo).times(2)
      Hobo::Config.run { |config| obj.foo }
      Hobo::Config.run { |config| obj.foo }
      Hobo::Config.execute!
    end

    should "run the blocks with the same config object" do
      config = mock("config")
      config.expects(:foo).twice
      Hobo::Config.stubs(:config).returns(config)
      Hobo::Config.run { |config| config.foo }
      Hobo::Config.run { |config| config.foo }
      Hobo::Config.execute!
    end
  end
end
