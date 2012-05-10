require File.expand_path("../base", __FILE__)

describe Vagrant do
  it "has the path to the source root" do
    described_class.source_root.should == Pathname.new(File.expand_path("../../../", __FILE__))
  end

  describe "plugin superclass" do
    it "returns the proper class for version 1" do
      described_class.plugin("1").should == Vagrant::Plugin::V1
    end

    it "raises an exception if an unsupported version is given" do
      expect { described_class.plugin("88") }.
        to raise_error(ArgumentError)
    end
  end

  describe "requiring plugins" do
    it "should require the plugin given" do
      # For now, just require a stdlib
      expect { described_class.require_plugin "set" }.
        to_not raise_error
    end

    it "should raise an error if the file doesn't exist" do
      expect { described_class.require_plugin("i_dont_exist") }.
        to raise_error(Vagrant::Errors::PluginLoadError)
    end
  end
end
