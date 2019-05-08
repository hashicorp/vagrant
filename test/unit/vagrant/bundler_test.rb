require "tmpdir"
require_relative "../base"

require "vagrant/bundler"

describe Vagrant::Bundler do
  include_context "unit"

  let(:iso_env) { isolated_environment }
  let(:env) { iso_env.create_vagrant_env }

  before do
    @tmpdir = Dir.mktmpdir("vagrant-bundler-test")
    @vh = ENV["VAGRANT_HOME"]
    ENV["VAGRANT_HOME"] = @tmpdir
  end

  after do
    ENV["VAGRANT_HOME"] = @vh
    FileUtils.rm_rf(@tmpdir)
  end

  it "should isolate gem path based on Ruby version" do
    expect(subject.plugin_gem_path.to_s).to end_with(RUBY_VERSION)
  end

  it "should not have an env_plugin_gem_path by default" do
    expect(subject.env_plugin_gem_path).to be_nil
  end

  describe "#initialize" do
    let(:gemrc_location) { "C:\\My\\Config\\File" }

    it "should set up GEMRC through a flag instead of GEMRC" do
      allow(ENV).to receive(:[]).with("VAGRANT_HOME")
      allow(ENV).to receive(:[]).with("USERPROFILE")

      allow(ENV).to receive(:[]).with("GEMRC").and_return(gemrc_location)
      expect(Gem::ConfigFile).to receive(:new).with(["--config-file", gemrc_location])
      init_subject = described_class.new
    end
  end

  describe "#deinit" do
    it "should provide method for backwards compatibility" do
      subject.deinit
    end
  end

  describe "DEFAULT_GEM_SOURCES" do
    it "should list hashicorp gemstore first" do
      expect(described_class.const_get(:DEFAULT_GEM_SOURCES).first).to eq(
        described_class.const_get(:HASHICORP_GEMSTORE))
    end
  end

  describe "#init!" do
    context "Gem.sources" do
      before {
        Gem.sources.clear
        Gem.sources << "https://rubygems.org/" }

      it "should add hashicorp gem store" do
        subject.init!([])
        expect(Gem.sources).to include(described_class.const_get(:HASHICORP_GEMSTORE))
      end

      it "should add hashicorp gem store to start of sources list" do
        subject.init!([])
        expect(Gem.sources.sources.first.uri.to_s).to eq(described_class.const_get(:HASHICORP_GEMSTORE))
      end
    end
  end

  describe "#install" do
    let(:plugins){ {"my-plugin" => {"gem_version" => "> 0"}} }

    it "should pass plugin information hash to internal install" do
      expect(subject).to receive(:internal_install).with(plugins, any_args)
      subject.install(plugins)
    end

    it "should not include any update plugins" do
      expect(subject).to receive(:internal_install).with(anything, nil, any_args)
      subject.install(plugins)
    end

    it "should flag local when local is true" do
      expect(subject).to receive(:internal_install).with(any_args, env_local: true)
      subject.install(plugins, true)
    end

    it "should not flag local when local is not set" do
      expect(subject).to receive(:internal_install).with(any_args, env_local: false)
      subject.install(plugins)
    end
  end

  describe "#install_local" do
    let(:plugin_source){ double("plugin_source", spec: plugin_spec) }
    let(:plugin_spec){ double("plugin_spec", name: plugin_name, version: plugin_version) }
    let(:plugin_name){ "PLUGIN_NAME" }
    let(:plugin_version){ "1.0.0" }
    let(:plugin_path){ "PLUGIN_PATH" }
    let(:sources){ "SOURCES" }

    before do
      allow(Gem::Source::SpecificFile).to receive(:new).and_return(plugin_source)
      allow(subject).to receive(:internal_install)
    end

    it "should return plugin gem specification" do
      expect(subject.install_local(plugin_path)).to eq(plugin_spec)
    end

    it "should set custom sources" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(info[plugin_name]["sources"]).to eq(sources)
      end
      subject.install_local(plugin_path, sources: sources)
    end

    it "should not set the update parameter" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(update).to be_nil
      end
      subject.install_local(plugin_path)
    end

    it "should not set plugin as environment local by default" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(opts[:env_local]).to be_falsey
      end
      subject.install_local(plugin_path)
    end

    it "should set if plugin is environment local" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(opts[:env_local]).to be_truthy
      end
      subject.install_local(plugin_path, env_local: true)
    end
  end

  describe "#update" do
    let(:plugins){ :plugins }
    let(:specific){ [] }

    after{ subject.update(plugins, specific) }

    it "should mark update as true" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(update).to be_truthy
      end
    end

    context "with specific plugins named" do
      let(:specific){ ["PLUGIN_NAME"] }

      it "should set update to specific names" do
        expect(subject).to receive(:internal_install) do |info, update, opts|
          expect(update[:gems]).to eq(specific)
        end
      end
    end
  end
end
