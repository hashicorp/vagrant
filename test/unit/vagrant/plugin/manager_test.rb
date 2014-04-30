require "json"
require "pathname"

require "vagrant/plugin"
require "vagrant/plugin/manager"
require "vagrant/plugin/state_file"

require File.expand_path("../../../base", __FILE__)

describe Vagrant::Plugin::Manager do
  include_context "unit"

  let(:path) do
    f = Tempfile.new("vagrant")
    p = f.path
    f.close
    f.unlink
    Pathname.new(p)
  end

  let(:bundler) { double("bundler") }

  after do
    path.unlink if path.file?
  end

  before do
    Vagrant::Bundler.stub(instance: bundler)
  end

  subject { described_class.new(path) }

  describe "#install_plugin" do
    it "installs the plugin and adds it to the state file" do
      specs = Array.new(5) { Gem::Specification.new }
      specs[3].name = "foo"
      expect(bundler).to receive(:install).once.with { |plugins, local|
        expect(plugins).to have_key("foo")
        expect(local).to be_false
      }.and_return(specs)

      result = subject.install_plugin("foo")

      # It should return the spec of the installed plugin
      expect(result).to eql(specs[3])

      # It should've added the plugin to the state
      expect(subject.installed_plugins).to have_key("foo")
    end

    it "masks GemNotFound with our error" do
      expect(bundler).to receive(:install).and_raise(Bundler::GemNotFound)

      expect { subject.install_plugin("foo") }.
        to raise_error(Vagrant::Errors::PluginGemNotFound)
    end

    it "masks bundler errors with our own error" do
      expect(bundler).to receive(:install).and_raise(Bundler::InstallError)

      expect { subject.install_plugin("foo") }.
        to raise_error(Vagrant::Errors::BundlerError)
    end

    it "can install a local gem" do
      name    = "foo.gem"
      version = "1.0"

      local_spec = Gem::Specification.new
      local_spec.name = "bar"
      local_spec.version = version

      expect(bundler).to receive(:install_local).with(name).
        ordered.and_return(local_spec)

      expect(bundler).to receive(:install).once.with { |plugins, local|
        expect(plugins).to have_key("bar")
        expect(plugins["bar"]["gem_version"]).to eql("#{version}")
        expect(local).to be_true
      }.ordered.and_return([local_spec])

      subject.install_plugin(name)

      plugins = subject.installed_plugins
      expect(plugins).to have_key("bar")
      expect(plugins["bar"]["gem_version"]).to eql("1.0")
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
        expect(bundler).to receive(:install).once.with { |plugins, local|
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eql(">= 0.1.0")
          expect(local).to be_false
        }.and_return(specs)

        subject.install_plugin("foo", version: ">= 0.1.0")

        plugins = subject.installed_plugins
        expect(plugins).to have_key("foo")
        expect(plugins["foo"]["gem_version"]).to eql(">= 0.1.0")
      end

      it "installs with an exact version but doesn't constrain" do
        expect(bundler).to receive(:install).once.with { |plugins, local|
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eql("0.1.0")
          expect(local).to be_false
        }.and_return(specs)

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
      expect(bundler).to receive(:clean).and_raise(Bundler::InstallError)

      expect { subject.uninstall_plugin("foo") }.
        to raise_error(Vagrant::Errors::BundlerError)
    end

    context "with a system file" do
      let(:systems_path) { temporary_file }

      before do
        systems_path.unlink

        described_class.stub(system_plugins_file: systems_path)

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
        expect(plugins["foo"]["system"]).to be_true
      end

      it "raises an error if uninstalling a system gem" do
        expect { subject.uninstall_plugin("bar") }.
          to raise_error(Vagrant::Errors::PluginUninstallSystem)
      end
    end
  end

  describe "#update_plugins" do
    it "masks bundler errors with our own error" do
      expect(bundler).to receive(:update).and_raise(Bundler::InstallError)

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

        described_class.stub(system_plugins_file: systems_path)

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
          expect(plugins["foo"]["system"]).to be_false
          expect(plugins).to have_key("bar")
          expect(plugins["bar"]["system"]).to be_true
        end
      end
    end
  end
end
