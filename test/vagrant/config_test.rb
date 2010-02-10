require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase
  context "accessing configuration" do
    setup do
      Vagrant::Config.run { |config| }
      Vagrant::Config.execute!
    end

    should "forward config to the class method" do
      assert_equal Vagrant.config, Vagrant::Config.config
    end
  end

  context "initializing" do
    teardown do
      Vagrant::Config.instance_variable_set(:@config_runners, nil)
      Vagrant::Config.instance_variable_set(:@config, nil)
    end

    should "not run the blocks right away" do
      obj = mock("obj")
      obj.expects(:foo).never
      Vagrant::Config.run { |config| obj.foo }
      Vagrant::Config.run { |config| obj.foo }
      Vagrant::Config.run { |config| obj.foo }
    end

    should "run the blocks when execute! is ran" do
      obj = mock("obj")
      obj.expects(:foo).times(2)
      Vagrant::Config.run { |config| obj.foo }
      Vagrant::Config.run { |config| obj.foo }
      Vagrant::Config.execute!
    end

    should "run the blocks with the same config object" do
      config = mock("config")
      config.expects(:foo).twice
      Vagrant::Config.stubs(:config).returns(config)
      Vagrant::Config.run { |config| config.foo }
      Vagrant::Config.run { |config| config.foo }
      Vagrant::Config.execute!
    end
  end
end
