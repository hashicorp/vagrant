require "test_helper"

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

    should "empty the proc stack" do
      assert !Vagrant::Config.proc_stack.empty?
      Vagrant::Config.reset!
      assert Vagrant::Config.proc_stack.empty?
    end

    should "reload the config object based on the given environment" do
      env = mock("env")
      Vagrant::Config.expects(:config).with(env).once
      Vagrant::Config.reset!(env)
    end
  end

  context "initializing" do
    setup do
      Vagrant::Config.reset!
    end

    should "add the given block to the proc stack" do
      proc = Proc.new {}
      Vagrant::Config.run(&proc)
      assert_equal [proc], Vagrant::Config.proc_stack
    end

    should "run the proc stack with the config when execute is called" do
      Vagrant::Config.expects(:run_procs!).with(Vagrant::Config.config).once
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

    should "return the configuration on execute!" do
      Vagrant::Config.run {}
      result = Vagrant::Config.execute!
      assert result.is_a?(Vagrant::Config::Top)
    end

    should "use given configuration object if given" do
      fake_env = mock("env")
      config = Vagrant::Config::Top.new(fake_env)
      result = Vagrant::Config.execute!(config)
      assert_equal config.env, result.env
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
        env = mock('env')

        5.times do |i|
          key = "key#{i}"
          klass = mock("klass#{i}")
          instance = mock("instance#{i}")
          instance.expects(:env=).with(env)
          klass.expects(:new).returns(instance)
          @configures_list << [key, klass]
        end

        Vagrant::Config::Top.new(env)
      end

      should "allow reading via methods" do
        key = "my_foo_bar_key"
        klass = mock("klass")
        instance = mock("instance")
        instance.stubs(:env=)
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

    context "deep cloning" do
      class DeepCloneConfig < Vagrant::Config::Base
        attr_accessor :attribute
      end

      setup do
        Vagrant::Config::Top.configures :deep, DeepCloneConfig
        @top = Vagrant::Config::Top.new
        @top.deep.attribute = [1,2,3]
      end

      should "deep clone the object" do
        copy = @top.deep_clone
        copy.deep.attribute << 4
        assert_not_equal @top.deep.attribute, copy.deep.attribute
        assert_equal 3, @top.deep.attribute.length
        assert_equal 4, copy.deep.attribute.length
      end
    end
  end
end
