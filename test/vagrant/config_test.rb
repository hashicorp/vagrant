require "test_helper"

class ConfigTest < Test::Unit::TestCase
  context "the ssh config" do
    setup do
      @env = mock_environment
      @env.stubs(:root_path).returns("foo")
    end

    should "expand any path when requesting the value" do
      result = File.expand_path(@env.config.ssh[:private_key_path], @env.root_path)
      assert_equal result, @env.config.ssh.private_key_path
    end
  end

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

    context "converting to JSON" do
      should "convert instance variable hash to json" do
        @json = mock("json")
        @iv_hash = mock("iv_hash")
        @iv_hash.expects(:to_json).once.returns(@json)
        @base.expects(:instance_variables_hash).returns(@iv_hash)
        assert_equal @json, @base.to_json
      end

      should "not include env in the JSON hash" do
        @base.env = "FOO"
        hash = @base.instance_variables_hash
        assert !hash.has_key?(:env)
      end
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

  context "vagrant configuration" do
    setup do
      @config = Vagrant::Config::VagrantConfig.new
    end

    should "return nil if home is nil" do
      File.expects(:expand_path).never
      assert @config.home.nil?
    end

    should "expand the path if home is not nil" do
      @config.home = "foo"
      File.expects(:expand_path).with("foo").once.returns("result")
      assert_equal "result", @config.home
    end
  end

  context "VM configuration" do
    setup do
      @env = mock_environment
      @config = @env.config.vm
      @env.config.ssh.username = @username
    end

    context "defining VMs" do
      should "store the proc by name but not run it" do
        foo = mock("proc")
        foo.expects(:call).never

        proc = Proc.new { foo.call }
        @config.define(:name, &proc)
        assert @config.defined_vms[:name].proc_stack.include?(proc)
      end

      should "store the options" do
        @config.define(:name, :set => true)
        assert @config.defined_vms[:name].options[:set]
      end

      should "not have multi-VMs by default" do
        assert !@config.has_multi_vms?
      end

      should "have multi-VMs once one is specified" do
        @config.define(:foo) {}
        assert @config.has_multi_vms?
      end
    end

    context "customizing" do
      should "include the stacked proc runner module" do
        assert @config.class.included_modules.include?(Vagrant::Util::StackedProcRunner)
      end

      should "add the customize proc to the proc stack" do
        proc = Proc.new {}
        @config.customize(&proc)
        assert_equal [proc], @config.proc_stack
      end
    end

    context "uid/gid" do
      should "return the shared folder UID if set" do
        @config.shared_folder_uid = "foo"
        assert_equal "foo", @config.shared_folder_uid
      end

      should "return the SSH username if UID not set" do
        @config.shared_folder_uid = nil
        assert_equal @username, @config.shared_folder_uid
      end

      should "return the shared folder GID if set" do
        @config.shared_folder_gid = "foo"
        assert_equal "foo", @config.shared_folder_gid
      end

      should "return the SSH username if GID not set" do
        @config.shared_folder_gid = nil
        assert_equal @username, @config.shared_folder_gid
      end
    end
  end
end
