require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::V1 do
  include_context "unit"

  describe "empty" do
    it "returns an empty configuration object" do
      result = described_class.init
      result.should be_kind_of(Vagrant::Config::V1::Root)
    end
  end

  describe "loading" do
    it "should configure with all plugin config keys loaded" do
      # Register a plugin for our test
      plugin_class = Class.new(Vagrant.plugin("1")) do
        name "test"
        config "foo" do
          Class.new do
            attr_accessor :bar
          end
        end
      end

      # Create the proc we're testing
      config_proc = Proc.new do |config|
        config.foo.bar = "value"
      end

      begin
        # Test that it works properly
        config = described_class.load(config_proc)
        config.foo.bar.should == "value"
      ensure
        # We have to unregister the plugin so that future tests
        # aren't mucked up.
        plugin_class.unregister!
      end
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
