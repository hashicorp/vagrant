require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase
  context "adding configures" do
    should "forward the method to the Top class" do
      key = mock("key")
      klass = mock("klass")
      Vagrant::Config::Top.expects(:configures).with(key, klass)
      Vagrant::Config.configures(key, klass)
    end
  end

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

  context "top config class" do
    setup do
      @configures_list = []
      Vagrant::Config::Top.stubs(:configures_list).returns(@configures_list)
    end

    context "adding configure keys" do
      setup do
        @key = "top_config_foo"
        @klass = mock("klass")
      end

      should "add key and klass to configures list" do
        @configures_list.expects(:<<).with([@key, @klass])
        Vagrant::Config::Top.configures(@key, @klass)
      end
    end

    context "configuration keys on instance" do
      setup do
        @configures_list.clear
      end

      should "initialize each configurer and set it to its key" do
        5.times do |i|
          key = "key#{i}"
          klass = mock("klass#{i}")
          instance = mock("instance#{i}")
          klass.expects(:new).returns(instance)
          @configures_list << [key, klass]
        end

        Vagrant::Config::Top.new
      end

      should "allow reading via methods" do
        key = "my_foo_bar_key"
        klass = mock("klass")
        instance = mock("instance")
        klass.expects(:new).returns(instance)
        Vagrant::Config::Top.configures(key, klass)

        config = Vagrant::Config::Top.new
        assert_equal instance, config.send(key)
      end
    end

    context "loaded status" do
      setup do
        @top= Vagrant::Config::Top.new
      end

      should "not be loaded by default" do
        assert !@top.loaded?
      end

      should "be loaded after calling loaded!" do
        @top.loaded!
        assert @top.loaded?
      end
    end
  end
end
