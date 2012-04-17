require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::V1 do
  include_context "unit"

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
end
