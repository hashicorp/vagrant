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

    describe "v2" do
      it "returns the proper class for version 2" do
        described_class.plugin("2").should == Vagrant::Plugin::V2::Plugin
      end

      it "returns the proper components for version 2" do
        described_class.plugin("2", :command).should == Vagrant::Plugin::V2::Command
        described_class.plugin("2", :communicator).should == Vagrant::Plugin::V2::Communicator
        described_class.plugin("2", :config).should == Vagrant::Plugin::V2::Config
        described_class.plugin("2", :guest).should == Vagrant::Plugin::V2::Guest
        described_class.plugin("2", :host).should == Vagrant::Plugin::V2::Host
        described_class.plugin("2", :provider).should == Vagrant::Plugin::V2::Provider
        described_class.plugin("2", :provisioner).should == Vagrant::Plugin::V2::Provisioner
        described_class.plugin("2", :synced_folder).should == Vagrant::Plugin::V2::SyncedFolder
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

    it "should add the gem name to plugin manager" do
      expect(described_class.plugin("2").manager).
        to receive(:plugin_required).with("set")
      described_class.require_plugin "set"
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
    before(:each) do
      Class.new(described_class.plugin("2")) do
        name "i_am_installed"
      end
      manager.plugin_required("plugin_gem")
    end
    after(:each) do
      manager.reset!
    end
    let(:manager) { described_class.plugin("2").manager }

    it "should find the installed plugin by the gem name" do
      expect(described_class.has_plugin?("plugin_gem")).to be_true
    end

    it "should find the installed plugin by the registered name" do
      expect(described_class.has_plugin?("i_am_installed")).to be_true
    end

    it "should return false if the plugin is not installed" do
      expect(described_class.has_plugin?("i_dont_exist")).to be_false
    end
  end

  describe "require_version" do
    it "should succeed if valid range" do
      expect { described_class.require_version(Vagrant::VERSION) }.
        to_not raise_error
    end

    it "should not succeed if bad range" do
      expect { described_class.require_version("> #{Vagrant::VERSION}") }.
        to raise_error(Vagrant::Errors::VagrantVersionBad)
    end
  end
end
