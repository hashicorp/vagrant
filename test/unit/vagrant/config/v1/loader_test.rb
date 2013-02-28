require "ostruct"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V1::Loader do
  include_context "unit"

  before(:each) do
    # Force the V1 loader to believe that we are in V1
    stub_const("Vagrant::Config::CURRENT_VERSION", "1")
  end

  describe "empty" do
    it "returns an empty configuration object" do
      result = described_class.init
      result.should be_kind_of(Vagrant::Config::V1::Root)
    end

    it "returns an object with all configuration keys loaded if V1" do
      # Make sure we're version 1
      stub_const("Vagrant::Config::CURRENT_VERSION", "1")

      # Register some config classes.
      register_plugin("1") do |p|
        p.config("foo") { OpenStruct }
        p.config("bar", true) { OpenStruct }
      end

      # Test that we have all keys
      result = described_class.init
      result.foo.should be_kind_of(OpenStruct)
      result.bar.should be_kind_of(OpenStruct)
    end

    it "returns only upgradable config objects if not V1" do
      # Make sure we're NOT version 1
      stub_const("Vagrant::Config::CURRENT_VERSION", "2")

      # Register some config classes.
      register_plugin("1") do |p|
        p.config("foo") { OpenStruct }
        p.config("bar", true) { OpenStruct }
      end

      # Test that we have all keys
      result = described_class.init
      result.bar.should be_kind_of(OpenStruct)
    end
  end

  describe "finalizing" do
    it "should call `#finalize` on the configuration object" do
      # Register a plugin for our test
      register_plugin("1") do |plugin|
        plugin.config "foo" do
          Class.new do
            attr_accessor :bar

            def finalize!
              @bar = "finalized"
            end
          end
        end
      end

      # Create the proc we're testing
      config_proc = Proc.new do |config|
        config.foo.bar = "value"
      end

      # Test that it works properly
      config = described_class.load(config_proc)
      config.foo.bar.should == "value"

      # Finalize it
      described_class.finalize(config)
      config.foo.bar.should == "finalized"
    end
  end

  describe "loading" do
    it "should configure with all plugin config keys loaded" do
      # Register a plugin for our test
      register_plugin("1") do |plugin|
        plugin.config("foo") { OpenStruct }
      end

      # Create the proc we're testing
      config_proc = Proc.new do |config|
        config.foo.bar = "value"
      end

      # Test that it works properly
      config = described_class.load(config_proc)
      config.foo.bar.should == "value"
    end
  end

  describe "merging" do
    it "should merge available configuration keys" do
      old = Vagrant::Config::V1::Root.new({ :foo => Object })
      new = Vagrant::Config::V1::Root.new({ :bar => Object })
      result = described_class.merge(old, new)
      result.foo.should be_kind_of(Object)
      result.bar.should be_kind_of(Object)
    end

    it "should merge instantiated objects" do
      config_class = Class.new do
        attr_accessor :value
      end

      old = Vagrant::Config::V1::Root.new({ :foo => config_class })
      old.foo.value = "old"

      new = Vagrant::Config::V1::Root.new({ :bar => config_class })
      new.bar.value = "new"

      result = described_class.merge(old, new)
      result.foo.value.should == "old"
      result.bar.value.should == "new"
    end

    it "should merge conflicting classes by calling `merge`" do
      config_class = Class.new do
        attr_accessor :value

        def merge(new)
          result       = self.class.new
          result.value = @value + new.value
          result
        end
      end

      old = Vagrant::Config::V1::Root.new({ :foo => config_class })
      old.foo.value = 10

      new = Vagrant::Config::V1::Root.new({ :foo => config_class })
      new.foo.value = 15

      result = described_class.merge(old, new)
      result.foo.value.should == 25
    end
  end
end
