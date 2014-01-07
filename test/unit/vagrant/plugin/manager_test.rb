require "json"
require "pathname"

require "vagrant/plugin"
require "vagrant/plugin/manager"
require "vagrant/plugin/state_file"

require File.expand_path("../../../base", __FILE__)

describe Vagrant::Plugin::Manager do
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
      bundler.should_receive(:install).once.with do |plugins, local|
        expect(plugins).to have_key("foo")
        expect(local).to be_false
      end.and_return(specs)

      result = subject.install_plugin("foo")

      # It should return the spec of the installed plugin
      expect(result).to eql(specs[3])

      # It should've added the plugin to the state
      expect(subject.installed_plugins).to have_key("foo")
    end

    it "masks GemNotFound with our error" do
      bundler.should_receive(:install).and_raise(Bundler::GemNotFound)

      expect { subject.install_plugin("foo") }.
        to raise_error(Vagrant::Errors::PluginGemNotFound)
    end

    it "masks bundler errors with our own error" do
      bundler.should_receive(:install).and_raise(Bundler::InstallError)

      expect { subject.install_plugin("foo") }.
        to raise_error(Vagrant::Errors::BundlerError)
    end

    it "can install a local gem" do
      name    = "foo.gem"
      version = "1.0"

      local_spec = Gem::Specification.new
      local_spec.name = "bar"
      local_spec.version = version

      bundler.should_receive(:install_local).with(name).
        ordered.and_return(local_spec)

      bundler.should_receive(:install).once.with do |plugins, local|
        expect(plugins).to have_key("bar")
        expect(plugins["bar"]["gem_version"]).to eql("#{version}")
        expect(local).to be_true
      end.ordered.and_return([local_spec])

      subject.install_plugin(name)

      plugins = subject.installed_plugins
      expect(plugins).to have_key("bar")
      expect(plugins["bar"]["gem_version"]).to eql("")
    end

    describe "installation options" do
      let(:specs) do
        specs = Array.new(5) { Gem::Specification.new }
        specs[3].name = "foo"
        specs
      end

      before do
        bundler.stub(:install).and_return(specs)
      end

      it "installs a version with constraints" do
        bundler.should_receive(:install).once.with do |plugins, local|
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eql(">= 0.1.0")
          expect(local).to be_false
        end.and_return(specs)

        subject.install_plugin("foo", version: ">= 0.1.0")

        plugins = subject.installed_plugins
        expect(plugins).to have_key("foo")
        expect(plugins["foo"]["gem_version"]).to eql(">= 0.1.0")
      end

      it "installs with an exact version but doesn't constrain" do
        bundler.should_receive(:install).once.with do |plugins, local|
          expect(plugins).to have_key("foo")
          expect(plugins["foo"]["gem_version"]).to eql("0.1.0")
          expect(local).to be_false
        end.and_return(specs)

        subject.install_plugin("foo", version: "0.1.0")

        plugins = subject.installed_plugins
        expect(plugins).to have_key("foo")
        expect(plugins["foo"]["gem_version"]).to eql("")
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
      bundler.should_receive(:clean).once.with({})

      # Remove it
      subject.uninstall_plugin("foo")
      expect(subject.installed_plugins).to_not have_key("foo")
    end

    it "masks bundler errors with our own error" do
      bundler.should_receive(:clean).and_raise(Bundler::InstallError)

      expect { subject.uninstall_plugin("foo") }.
        to raise_error(Vagrant::Errors::BundlerError)
    end
  end

  describe "#update_plugins" do
    it "masks bundler errors with our own error" do
      bundler.should_receive(:update).and_raise(Bundler::InstallError)

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
      sf.add_plugin("foo")
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
  end
end
