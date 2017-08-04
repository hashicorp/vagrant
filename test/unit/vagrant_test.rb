require File.expand_path("../base", __FILE__)

describe Vagrant do
  include_context "unit"

  it "has the path to the source root" do
    expect(described_class.source_root).to eq(Pathname.new(File.expand_path("../../../", __FILE__)))
  end

  describe "plugin superclass" do
    describe "v1" do
      it "returns the proper class for version 1" do
        expect(described_class.plugin("1")).to eq(Vagrant::Plugin::V1::Plugin)
      end

      it "returns the proper components for version 1" do
        expect(described_class.plugin("1", :command)).to eq(Vagrant::Plugin::V1::Command)
        expect(described_class.plugin("1", :communicator)).to eq(Vagrant::Plugin::V1::Communicator)
        expect(described_class.plugin("1", :config)).to eq(Vagrant::Plugin::V1::Config)
        expect(described_class.plugin("1", :guest)).to eq(Vagrant::Plugin::V1::Guest)
        expect(described_class.plugin("1", :host)).to eq(Vagrant::Plugin::V1::Host)
        expect(described_class.plugin("1", :provider)).to eq(Vagrant::Plugin::V1::Provider)
        expect(described_class.plugin("1", :provisioner)).to eq(Vagrant::Plugin::V1::Provisioner)
      end
    end

    describe "v2" do
      it "returns the proper class for version 2" do
        expect(described_class.plugin("2")).to eq(Vagrant::Plugin::V2::Plugin)
      end

      it "returns the proper components for version 2" do
        expect(described_class.plugin("2", :command)).to eq(Vagrant::Plugin::V2::Command)
        expect(described_class.plugin("2", :communicator)).to eq(Vagrant::Plugin::V2::Communicator)
        expect(described_class.plugin("2", :config)).to eq(Vagrant::Plugin::V2::Config)
        expect(described_class.plugin("2", :guest)).to eq(Vagrant::Plugin::V2::Guest)
        expect(described_class.plugin("2", :host)).to eq(Vagrant::Plugin::V2::Host)
        expect(described_class.plugin("2", :provider)).to eq(Vagrant::Plugin::V2::Provider)
        expect(described_class.plugin("2", :provisioner)).to eq(Vagrant::Plugin::V2::Provisioner)
        expect(described_class.plugin("2", :synced_folder)).to eq(Vagrant::Plugin::V2::SyncedFolder)
      end
    end

    it "raises an exception if an unsupported version is given" do
      expect { described_class.plugin("88") }.
        to raise_error(ArgumentError)
    end
  end

  describe "has_plugin?" do
    after(:each) do
      manager.reset!
    end

    let(:manager) { described_class.plugin("2").manager }

    it "should find the installed plugin by the registered name" do
      Class.new(described_class.plugin(Vagrant::Config::CURRENT_VERSION)) do
        name "i_am_installed"
      end

      expect(described_class.has_plugin?("i_am_installed")).to be(true)
    end

    it "should return false if the plugin is not installed" do
      expect(described_class.has_plugin?("i_dont_exist")).to be(false)
    end

    it "finds plugins by gem name" do
      specs = [Gem::Specification.new]
      specs[0].name = "foo"
      allow(Vagrant::Plugin::Manager.instance).to receive(:installed_specs).and_return(specs)

      expect(described_class.has_plugin?("foo")).to be(true)
      expect(described_class.has_plugin?("bar")).to be(false)
    end

    it "finds plugins by gem name and version" do
      specs = [Gem::Specification.new]
      specs[0].name = "foo"
      specs[0].version = "1.2.3"
      allow(Vagrant::Plugin::Manager.instance).to receive(:installed_specs).and_return(specs)

      expect(described_class.has_plugin?("foo", "~> 1.2.0")).to be(true)
      expect(described_class.has_plugin?("foo", "~> 1.0.0")).to be(false)
      expect(described_class.has_plugin?("bar", "~> 1.2.0")).to be(false)
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

  describe "original_env" do
    before do
      ENV["VAGRANT_OLD_ENV_foo"] = "test"
      ENV["VAGRANT_OLD_ENV_bar"] = "test"
    end

    after do
      ENV["VAGRANT_OLD_ENV_foo"] = "test"
      ENV["VAGRANT_OLD_ENV_bar"] = "test"
    end

    it "should return the original environment" do
      expect(Vagrant.original_env).to eq(
        "foo" => "test",
        "bar" => "test",
      )
    end
  end
end
