require "test_helper"

class ConfigTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Config
  end

  context "with an instance" do
    setup do
      @env = vagrant_env
      @instance = @klass.new(@env)
    end

    should "initially have an empty queue" do
      assert @instance.queue.empty?
    end

    should "reset the config class on load, then execute" do
      seq = sequence("sequence")
      @klass.expects(:reset!).with(@env).in_sequence(seq)
      @klass.expects(:execute!).in_sequence(seq)
      @instance.load!
    end

    should "run the queue in the order given" do
      @instance.queue << Proc.new { |config| config.vm.box = "foo" }
      @instance.queue << Proc.new { |config| config.vm.box = "bar" }
      result = @instance.load!

      assert_equal "bar", result.vm.box
    end

    should "allow nested arrays" do
      queue = []
      queue << Proc.new { |config| config.vm.box = "foo" }
      queue << Proc.new { |config| config.vm.box = "bar" }
      @instance.queue << queue
      result = @instance.load!

      assert_equal "bar", result.vm.box
    end

    should "load a file if it exists" do
      filename = "foo"
      File.expects(:exist?).with(filename).returns(true)
      @instance.expects(:load).with(filename).once

      @instance.queue << filename
      @instance.load!
    end

    should "not load a file if it doesn't exist" do
      filename = "foo"
      File.expects(:exist?).with(filename).returns(false)
      @instance.expects(:load).with(filename).never

      @instance.queue << filename
      @instance.load!
    end

    should "raise an exception if there is a syntax error in a file" do
      @instance.queue << "foo"
      File.expects(:exist?).with("foo").returns(true)
      @instance.expects(:load).with("foo").raises(SyntaxError.new)

      assert_raises(Vagrant::Errors::VagrantfileSyntaxError) {
        @instance.load!
      }
    end
  end

  context "resetting" do
    setup do
      @klass.reset!(vagrant_env)
      @klass::Top.any_instance.stubs(:validate!)
      @klass.run { |config| }
      @klass.execute!
    end

    should "return the same config object typically" do
      config = @klass.config
      assert config.equal?(@klass.config)
    end

    should "create a new object if cleared" do
      config = @klass.config
      @klass.reset!
      assert !config.equal?(@klass.config)
    end

    should "empty the proc stack" do
      assert !@klass.proc_stack.empty?
      @klass.reset!
      assert @klass.proc_stack.empty?
    end

    should "reload the config object based on the given environment" do
      env = mock("env")
      @klass.expects(:config).with(env).once
      @klass.reset!(env)
    end
  end

  context "initializing" do
    setup do
      @klass.reset!(vagrant_env)
    end

    should "add the given block to the proc stack" do
      proc = Proc.new {}
      @klass.run(&proc)
      assert_equal [proc], @klass.proc_stack
    end

    should "return the configuration on execute!" do
      @klass.run {}
      result = @klass.execute!
      assert result.is_a?(@klass::Top)
    end
  end

  context "top config class" do
    setup do
      @configures_list = {}
      @klass::Top.stubs(:configures_list).returns(@configures_list)
    end

    context "adding configure keys" do
      setup do
        @key = "top_config_foo"
        @config_klass = mock("klass")
      end

      should "add key and klass to configures list" do
        @klass::Top.configures(@key, @config_klass)
        assert_equal @config_klass, @configures_list[@key]
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
          instance.expects(:top=).with() do |top|
            assert top.is_a?(@klass::Top)
            true
          end
          klass.expects(:new).returns(instance)
          @configures_list[key] = klass
        end

        @klass::Top.new(env)
      end

      should "allow reading via methods" do
        key = "my_foo_bar_key"
        klass = mock("klass")
        instance = mock("instance")
        instance.stubs(:env=)
        instance.stubs(:top=)
        klass.expects(:new).returns(instance)
        @klass::Top.configures(key, klass)

        config = @klass::Top.new
        assert_equal instance, config.send(key)
      end
    end

    context "validation" do
      should "do nothing if no errors are added" do
        valid_class = Class.new(@klass::Base)
        @klass::Top.configures(:subconfig, valid_class)
        instance = @klass::Top.new
        assert_nothing_raised { instance.validate! }
      end

      should "raise an exception if there are errors" do
        invalid_class = Class.new(@klass::Base) do
          def validate(errors)
            errors.add("vagrant.test.errors.test_key")
          end
        end

        @klass::Top.configures(:subconfig, invalid_class)
        instance = @klass::Top.new

        assert_raises(Vagrant::Errors::ConfigValidationFailed) {
          instance.validate!
        }
      end
    end
  end
end
