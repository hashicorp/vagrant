# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "json"
require "pathname"

require "vagrant/plugin"
require "vagrant/plugin/manager"
require "vagrant/plugin/state_file"
require "vagrant/util/deep_merge"
require File.expand_path("../../../base", __FILE__)

describe Vagrant::Plugin::Manager do
  include_context "unit"

  let(:path) do
    Pathname.new(Dir::Tmpname.create("vagrant-test-plugin-manager") {})
  end

  let(:bundler) { double("bundler") }

  after do
    path.unlink if path.file?
  end

  before do
    allow(Vagrant::Bundler).to receive(:instance).and_return(bundler)
  end

  subject { described_class.new(path) }

  describe "#globalize!" do
    let(:plugins) { double("plugins") }

    before do
      allow(subject).to receive(:bundler_init)
      allow(subject).to receive(:installed_plugins).and_return(plugins)
    end

    it "should init bundler with installed plugins" do
      expect(subject).to receive(:bundler_init).with(plugins, anything)
      subject.globalize!
    end

    it "should return installed plugins" do
      expect(subject.globalize!).to eq(plugins)
    end
  end

  describe "#localize!" do
    let(:env) { double("env", local_data_path: local_data_path) }
    let(:local_data_path) { double("local_data_path") }
    let(:plugins) { double("plugins") }
    let(:state_file) { double("state_file", path: double("state_file_path"), installed_plugins: plugins) }

    before do
      allow(Vagrant::Plugin::StateFile).to receive(:new).and_return(state_file)
      allow(bundler).to receive(:environment_path=)
      allow(local_data_path).to receive(:join).and_return(local_data_path) if local_data_path
      allow(subject).to receive(:bundler_init)
    end

    context "without local data path defined" do
      let(:local_data_path) { nil }

      it "should not do any initialization" do
        expect(subject).not_to receive(:bundler_init)
        subject.localize!(env)
      end

      it "should return nil" do
        expect(subject.localize!(env)).to be_nil
      end
    end

    it "should run bundler initialization" do
      expect(subject).to receive(:bundler_init).with(plugins, anything)
      subject.localize!(env)
    end

    it "should return plugins" do
      expect(subject.localize!(env)).to eq(plugins)
    end
  end

  describe "#ready?" do
    let(:plugins) { double("plugins") }
    let(:env) { double("env", local_data_path: nil) }

    before do
      allow(subject).to receive(:bundler_init)
    end

    it "should be false by default" do
      expect(subject.ready?).to be_falsey
    end

    it "should be false when only globalize! has been called" do
      subject.globalize!
      expect(subject.ready?).to be_falsey
    end

    it "should be false when only localize! has been called" do
      subject.localize!(env)
      expect(subject.ready?).to be_falsey
    end

    it "should be true when both localize! and globalize! have been called" do
      subject.globalize!
      subject.localize!(env)
      expect(subject.ready?).to be_truthy
    end
  end

  describe "#bundler_init" do
    let(:plugins) { {"plugin_name" => {}} }

    before do
      allow(Vagrant).to receive(:plugins_init?).and_return(true)
      allow(bundler).to receive(:init!)
    end

    it "should init the bundler instance with plugins" do
      expect(bundler).to receive(:init!).with(plugins, any_args)
      subject.bundler_init(plugins)
    end

    it "should return nil" do
      expect(subject.bundler_init(plugins)).to be_nil
    end

    context "with plugin init disabled" do
      before { expect(Vagrant).to receive(:plugins_init?).and_return(false) }

      it "should return nil" do
        expect(subject.bundler_init(plugins)).to be_nil
      end

      it "should not init the bundler instance" do
        expect(bundler).not_to receive(:init!).with(plugins)
        subject.bundler_init(plugins)
      end
    end
  end

  describe "#plugin_installed?" do
    let(:ready) { true }
    let(:specs) { [] }

    before do
      allow(subject).to receive(:ready?).and_return(ready)
      allow(subject).to receive(:installed_specs).and_return(specs)
    end

    context "when manager is ready" do
      it "should return false when plugin is not found" do
        expect(subject.plugin_installed?("vagrant-plugin")).to be_falsey
      end

      context "when plugin is installed" do
        let(:specs) { [Gem::Specification.new("vagrant-plugin", "1.2.3")] }

        it "should return true" do
          expect(subject.plugin_installed?("vagrant-plugin")).to be_truthy
        end

        it "should return true when version matches installed version" do
          expect(subject.plugin_installed?("vagrant-plugin", "1.2.3")).to be_truthy
        end

        it "should return true when version requirement is satisified by version" do
          expect(subject.plugin_installed?("vagrant-plugin", "> 1.0")).to be_truthy
        end

        it "should return false when version requirement is not satisified by version" do
          expect(subject.plugin_installed?("vagrant-plugin", "2.0")).to be_falsey
        end
      end
    end

    context "when manager is not ready" do
      let(:ready) { false }
      let(:plugins) { {} }
      before { allow(subject).to receive(:installed_plugins).and_return(plugins) }

      it "should check installed plugin data" do
        expect(subject).to receive(:installed_plugins).and_return(plugins)
        subject.plugin_installed?("vagrant-plugin")
      end

      it "should return false when plugin is not found" do
        expect(subject.plugin_installed?("vagrant-plugin")).to be_falsey
      end

      context "when plugin is installed" do
        let(:plugins) { {"vagrant-plugin" => {"installed_gem_version" => "1.2.3"}} }

        it "should return true" do
          expect(subject.plugin_installed?("vagrant-plugin")).to be_truthy
        end

        it "should return true when version matches installed version" do
          expect(subject.plugin_installed?("vagrant-plugin", "1.2.3")).to be_truthy
        end

        it "should return true when version requirement is satisified by version" do
          expect(subject.plugin_installed?("vagrant-plugin", "> 1.0")).to be_truthy
        end

        it "should return false when version requirement is not satisified by version" do
          expect(subject.plugin_installed?("vagrant-plugin", "2.0")).to be_falsey
        end
      end
    end
  end

  describe "#install_plugin" do
    it "installs the plugin and adds it to the state file" do
      specs = Array.new(5) { Gem::Specification.new }
      specs[3].name = "foo"
      expect(bundler).to receive(:install).once.with(any_args) { |plugins, local|
        expect(plugins).to have_key("foo")
        expect(local).to be_falsey
      }.and_return(specs)
      expect(bundler).to receive(:clean)

      result = subject.install_plugin("foo")

      # It should return the spec of the installed plugin
      expect(result).to eql(specs[3])

      # It should've added the plugin to the state
      expect(subject.installed_plugins).to have_key("foo")
    end

    it "masks GemNotFound with our error" do
      expect(bundler).to receive(:install).and_raise(Gem::GemNotFoundException)

      expect { subject.install_plugin("foo") }.
        to raise_error(Vagrant::Errors::PluginGemNotFound)
    end

    it "masks bundler errors with our own error" do
      expect(bundler).to receive(:install).and_raise(Gem::InstallError)

      expect { subject.install_plugin("foo") }.
        to raise_error(Vagrant::Errors::BundlerError)
    end

    it "can install a local gem" do
      name    = "foo.gem"
      version = "1.0"

      local_spec = Gem::Specification.new
      local_spec.name = "bar"
      local_spec.version = version

      expect(bundler).to receive(:install_local).with(name, {}).
        ordered.and_return(local_spec)

      expect(bundler).not_to receive(:install)
      expect(bundler).to receive(:clean)

      subject.install_plugin(name)

      plugins = subject.installed_plugins
      expect(plugins).to have_key("bar")
      expect(plugins["bar"]["gem_version"]).to eql("1.0")
    end

    context "with existing activation" do
      let(:value) { double("value") }

      before do
        expect(bundler).to receive(:install).and_return([])
        allow(bundler).to receive(:clean)
      end

      it "should locate existing activation if available" do
        expect(Gem::Specification).to receive(:find).and_return(value)
        expect(subject.install_plugin("foo")).to eq(value)
      end

      it "should raise an error if no activation is located" do
        expect(Gem::Specification).to receive(:find).and_return(nil)
        expect { subject.install_plugin("foo") }.to raise_error(Vagrant::Errors::PluginInstallFailed)
      end
    end

    describe "installation options" do
      let(:specs) do
        specs = Array.new(5) { Gem::Specification.new }
        specs[3].name = "foo"
        specs
      end

      before do
        allow(bundler).to receive(:install).and_return(specs)
      end

      it "installs a version with constraints" do
        expect(bundler).to receive(:install).once.with(any_args) { |plugins, local|
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eql(">= 0.1.0")
          expect(local).to be_falsey
        }.and_return(specs)
        expect(bundler).to receive(:clean)

        subject.install_plugin("foo", version: ">= 0.1.0")

        plugins = subject.installed_plugins
        expect(plugins).to have_key("foo")
        expect(plugins["foo"]["gem_version"]).to eql(">= 0.1.0")
      end

      it "installs with an exact version but doesn't constrain" do
        expect(bundler).to receive(:install).once.with(any_args) { |plugins, local|
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eql("0.1.0")
          expect(local).to be_falsey
        }.and_return(specs)
        expect(bundler).to receive(:clean)

        subject.install_plugin("foo", version: "0.1.0")

        plugins = subject.installed_plugins
        expect(plugins).to have_key("foo")
        expect(plugins["foo"]["gem_version"]).to eql("0.1.0")
      end
    end
  end

  describe "#uninstall_plugin" do
    it "removes the plugin from the state" do
      sf = Vagrant::Plugin::StateFile.new(path)
      sf.add_plugin("foo")

      # Sanity
      expect(subject.installed_plugins).to have_key("foo")

      # Test
      expect(bundler).to receive(:clean).once.with({})

      # Remove it
      subject.uninstall_plugin("foo")
      expect(subject.installed_plugins).to_not have_key("foo")
    end

    it "masks bundler errors with our own error" do
      sf = Vagrant::Plugin::StateFile.new(path)
      sf.add_plugin("foo")
      expect(bundler).to receive(:clean).and_raise(Gem::InstallError)

      expect { subject.uninstall_plugin("foo") }.
        to raise_error(Vagrant::Errors::BundlerError)
    end

    context "with a system file" do
      let(:systems_path) { temporary_file }

      before do
        systems_path.unlink

        allow(described_class).to receive(:system_plugins_file).and_return(systems_path)

        sf = Vagrant::Plugin::StateFile.new(systems_path)
        sf.add_plugin("foo", version: "0.2.0")
        sf.add_plugin("bar")
      end

      it "uninstalls the user plugin if it exists" do
        sf = Vagrant::Plugin::StateFile.new(path)
        sf.add_plugin("bar")

        # Test
        expect(bundler).to receive(:clean).once.with(anything)

        # Remove it
        subject.uninstall_plugin("bar")

        plugins = subject.installed_plugins
        expect(plugins["foo"]["system"]).to be(true)
      end

      it "raises an error if uninstalling a system gem" do
        expect { subject.uninstall_plugin("bar") }.
          to raise_error(Vagrant::Errors::PluginUninstallSystem)
      end
    end
  end

  describe "#update_plugins" do
    it "masks bundler errors with our own error" do
      expect(bundler).to receive(:update).and_raise(Gem::InstallError)

      expect { subject.update_plugins([]) }.
        to raise_error(Vagrant::Errors::BundlerError)
    end
  end

  context "without state" do
    describe "#installed_plugins" do
      it "is empty initially" do
        expect(subject.installed_plugins).to be_empty
      end
    end
  end

  context "with state" do
    before do
      sf = Vagrant::Plugin::StateFile.new(path)
      sf.add_plugin("foo", version: "0.1.0")
    end

    describe "#installed_plugins" do
      it "has the plugins" do
        plugins = subject.installed_plugins
        expect(plugins.length).to eql(1)
        expect(plugins).to have_key("foo")
      end
    end

    describe "#installed_specs" do
      it "has the plugins" do
        # We just add "i18n" because it is a dependency of Vagrant and
        # we know it will be there.
        sf = Vagrant::Plugin::StateFile.new(path)
        sf.add_plugin("i18n")

        specs = subject.installed_specs
        expect(specs.length).to eql(1)
        expect(specs.first.name).to eql("i18n")
      end
    end

    context "with system plugins" do
      let(:systems_path) { temporary_file }

      before do
        systems_path.unlink

        allow(described_class).to receive(:system_plugins_file).and_return(systems_path)

        sf = Vagrant::Plugin::StateFile.new(systems_path)
        sf.add_plugin("foo", version: "0.2.0")
        sf.add_plugin("bar")
      end

      describe "#installed_plugins" do
        it "has the plugins" do
          plugins = subject.installed_plugins
          expect(plugins.length).to eql(2)
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eq("0.1.0")
          expect(plugins["foo"]["system"]).to be_truthy
          expect(plugins).to have_key("bar")
          expect(plugins["bar"]["system"]).to be(true)
        end
      end
    end
  end
end
