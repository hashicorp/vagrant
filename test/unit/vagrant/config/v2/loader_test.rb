require "ostruct"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V2::Loader do
  include_context "unit"

  before(:each) do
    # Force the V2 loader to believe that we are in V2
    stub_const("Vagrant::Config::CURRENT_VERSION", "2")
  end

  describe "empty" do
    it "returns an empty configuration object" do
      result = described_class.init
      expect(result).to be_kind_of(Vagrant::Config::V2::Root)
    end
  end

  describe "finalizing" do
    it "should call `#finalize` on the configuration object" do
      # Register a plugin for our test
      register_plugin("2") do |plugin|
        plugin.config "foo" do
          Class.new(Vagrant.plugin("2", "config")) do
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
      expect(config.foo.bar).to eq("value")

      # Finalize it
      described_class.finalize(config)
      expect(config.foo.bar).to eq("finalized")
    end
  end

  describe "loading" do
    it "should configure with all plugin config keys loaded" do
      # Register a plugin for our test
      register_plugin("2") do |plugin|
        plugin.config("foo") { OpenStruct }
      end

      # Create the proc we're testing
      config_proc = Proc.new do |config|
        config.foo.bar = "value"
      end

      # Test that it works properly
      config = described_class.load(config_proc)
      expect(config.foo.bar).to eq("value")
    end
  end

  describe "merging" do
    it "should merge available configuration keys" do
      old = Vagrant::Config::V2::Root.new({ foo: Object })
      new = Vagrant::Config::V2::Root.new({ bar: Object })
      result = described_class.merge(old, new)
      expect(result.foo).to be_kind_of(Object)
      expect(result.bar).to be_kind_of(Object)
    end

    it "should merge instantiated objects" do
      config_class = Class.new do
        attr_accessor :value
      end

      old = Vagrant::Config::V2::Root.new({ foo: config_class })
      old.foo.value = "old"

      new = Vagrant::Config::V2::Root.new({ bar: config_class })
      new.bar.value = "new"

      result = described_class.merge(old, new)
      expect(result.foo.value).to eq("old")
      expect(result.bar.value).to eq("new")
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

      old = Vagrant::Config::V2::Root.new({ foo: config_class })
      old.foo.value = 10

      new = Vagrant::Config::V2::Root.new({ foo: config_class })
      new.foo.value = 15

      result = described_class.merge(old, new)
      expect(result.foo.value).to eq(25)
    end
  end

  describe "upgrading" do
    it "should continue fine if the key doesn't implement upgrade" do
      # Make an old V1 root object
      old = Vagrant::Config::V1::Root.new({ foo: Class.new })

      # It should work fine
      expect { result = described_class.upgrade(old) }.to_not raise_error
    end

    it "should upgrade the config if it implements the upgrade method" do
      # Create the old V1 class that will be upgraded
      config_class = Class.new do
        attr_accessor :value

        def upgrade(new)
          new.foo.value = value * 2

          [["foo"], ["bar"]]
        end
      end

      # Create the new V2 plugin it is writing to
      register_plugin("2") do |p|
        p.config("foo") { OpenStruct }
      end

      # Test it out!
      old = Vagrant::Config::V1::Root.new({ foo: config_class })
      old.foo.value = 5

      data = described_class.upgrade(old)
      expect(data[0].foo.value).to eq(10)
      expect(data[1]).to eq(["foo"])
      expect(data[2]).to eq(["bar"])
    end
  end
end
