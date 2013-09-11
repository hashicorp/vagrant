require File.expand_path("../base", __FILE__)

describe Vagrant do
  include_context "unit"

  it "has the path to the source root" do
    described_class.source_root.should == Pathname.new(File.expand_path("../../../", __FILE__))
  end

  describe "plugin superclass" do
    describe "v1" do
      it "returns the proper class for version 1" do
        described_class.plugin("1").should == Vagrant::Plugin::V1::Plugin
      end

      it "returns the proper components for version 1" do
        described_class.plugin("1", :command).should == Vagrant::Plugin::V1::Command
        described_class.plugin("1", :communicator).should == Vagrant::Plugin::V1::Communicator
        described_class.plugin("1", :config).should == Vagrant::Plugin::V1::Config
        described_class.plugin("1", :guest).should == Vagrant::Plugin::V1::Guest
        described_class.plugin("1", :host).should == Vagrant::Plugin::V1::Host
        described_class.plugin("1", :provider).should == Vagrant::Plugin::V1::Provider
        described_class.plugin("1", :provisioner).should == Vagrant::Plugin::V1::Provisioner
      end
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

    it "should raise an error if the loading failed in some other way" do
      plugin_dir  = temporary_dir
      plugin_path = plugin_dir.join("test.rb")
      plugin_path.open("w") do |f|
        f.write(%Q[require 'I_dont_exist'])
      end

      expect { described_class.require_plugin(plugin_path.to_s) }.
        to raise_error(Vagrant::Errors::PluginLoadFailed)
    end
  end

  describe "has_plugin?" do
    after(:each) do
      described_class.plugin('2').manager.reset!
    end

    it "should return true if the plugin is installed" do
      plugin = Class.new(described_class.plugin('2')) do
        name "i_am_installed"
      end

      described_class.has_plugin?("i_am_installed").should be_true
    end

    it "should return false if the plugin is not installed" do
      described_class.has_plugin?("i_dont_exist").should be_false
    end
  end
end
