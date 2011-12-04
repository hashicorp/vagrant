require "test_helper"

class ConfigTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Config
  end

  context "with an instance" do
    setup do
      @instance = @klass.new
    end

    should "load the config files in the given order" do
      names = %w{alpha beta gamma}

      @instance.load_order = [:alpha, :beta]

      names.each do |name|
        vagrantfile(vagrant_box(name), "config.vm.box = '#{name}'")
        @instance.set(name.to_sym, vagrant_box(name).join("Vagrantfile"))
      end

      config = @instance.load(nil)
      assert_equal "beta", config.vm.box
    end

    should "load the config as procs" do
      @instance.set(:proc, Proc.new { |config| config.vm.box = "proc" })
      @instance.load_order = [:proc]
      config = @instance.load(nil)

      assert_equal "proc", config.vm.box
    end

    should "load an array of procs" do
      @instance.set(:proc, [Proc.new { |config| config.vm.box = "proc" },
                            Proc.new { |config| config.vm.box = "proc2" }])
      @instance.load_order = [:proc]
      config = @instance.load(nil)

      assert_equal "proc2", config.vm.box
    end

    should "not care if a file doesn't exist" do
      @instance.load_order = [:foo]
      assert_nothing_raised { @instance.set(:foo, "i/dont/exist") }
      assert_nothing_raised { @instance.load(nil) }
    end

    should "not reload a file" do
      foo_path = vagrant_box("foo").join("Vagrantfile")

      vagrantfile(vagrant_box("foo"))
      @instance.set(:foo, foo_path)

      # Nothing should be raised in this case because the file isn't reloaded
      vagrantfile(vagrant_box("foo"), "^%&8318")
      assert_nothing_raised { @instance.set(:foo, foo_path) }
    end

    should "raise an exception if there is a syntax error in a file" do
      vagrantfile(vagrant_box("foo"), "^%&8318")

      assert_raises(Vagrant::Errors::VagrantfileSyntaxError) {
        @instance.set(:foo, vagrant_box("foo").join("Vagrantfile"))
      }
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
