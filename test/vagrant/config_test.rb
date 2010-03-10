require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase
  context "resetting" do
    setup do
      Vagrant::Config.run { |config| }
      Vagrant::Config.execute!
    end

    should "return the same config object typically" do
      config = Vagrant::Config.config
      assert config.equal?(Vagrant::Config.config)
    end

    should "create a new object if cleared" do
      config = Vagrant::Config.config
      Vagrant::Config.reset!
      assert !config.equal?(Vagrant::Config.config)
    end

    should "empty the runners" do
      assert !Vagrant::Config.config_runners.empty?
      Vagrant::Config.reset!
      assert Vagrant::Config.config_runners.empty?
    end
  end

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
      Vagrant::Config.reset!
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
      Vagrant::Config.run { |config| assert config }
      Vagrant::Config.run { |config| assert config }
      Vagrant::Config.execute!
    end

    should "not be loaded, initially" do
      assert !Vagrant::Config.config.loaded?
    end

    should "be loaded after running" do
      Vagrant::Config.run {}
      Vagrant::Config.execute!
      assert Vagrant::Config.config.loaded?
    end
  end

  context "base class" do
    setup do
      @base = Vagrant::Config::Base.new
    end

    should "forward [] access to methods" do
      @base.expects(:foo).once
      @base[:foo]
    end

    should "return a hash of instance variables" do
      data = { :foo => "bar", :bar => "baz" }

      data.each do |iv, value|
        @base.instance_variable_set("@#{iv}".to_sym, value)
      end

      result = @base.instance_variables_hash
      assert_equal data.length, result.length

      data.each do |iv, value|
        assert_equal value, result[iv]
      end
    end

    should "convert instance variable hash to json" do
      @json = mock("json")
      @iv_hash = mock("iv_hash")
      @iv_hash.expects(:to_json).once.returns(@json)
      @base.expects(:instance_variables_hash).returns(@iv_hash)
      assert_equal @json, @base.to_json
    end
  end

  context "chef config" do
    setup do
      @config = Vagrant::Config::ChefConfig.new
      @config.json = "HEY"
    end

    should "not include the 'json' key in the config dump" do
      result = JSON.parse(@config.to_json)
      assert !result.has_key?("json")
    end
  end
end
