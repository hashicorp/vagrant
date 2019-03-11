require "json"
require "pathname"

require File.expand_path("../../../base", __FILE__)

describe Vagrant::Plugin::StateFile do
  let(:path) do
    Pathname.new(Dir::Tmpname.create("vagrant-test-statefile") {})
  end

  after do
    path.unlink if path.file?
  end

  subject { described_class.new(path) }

  context "new usage" do
    it "should have no plugins without saving some" do
      expect(subject.installed_plugins).to be_empty
    end

    it "should have plugins when saving" do
      subject.add_plugin("foo")

      instance = described_class.new(path)
      plugins = instance.installed_plugins
      expect(plugins.length).to eql(1)
      expect(plugins["foo"]).to eql({
        "ruby_version"          => RUBY_VERSION,
        "vagrant_version"       => Vagrant::VERSION,
        "gem_version"           => "",
        "require"               => "",
        "sources"               => [],
        "installed_gem_version" => nil,
        "env_local"             => false,
      })
    end

    it "should check for plugins" do
      expect(subject.has_plugin?("foo")).to be(false)
      subject.add_plugin("foo")
      expect(subject.has_plugin?("foo")).to be(true)
    end

    it "should remove plugins" do
      subject.add_plugin("foo")
      subject.remove_plugin("foo")

      instance = described_class.new(path)
      expect(instance.installed_plugins).to be_empty
    end

    it "should store plugins uniquely" do
      subject.add_plugin("foo")
      subject.add_plugin("foo")

      instance = described_class.new(path)
      expect(instance.installed_plugins.keys).to eql(["foo"])
    end

    it "should store metadata" do
      subject.add_plugin("foo", version: "1.2.3")
      expect(subject.installed_plugins["foo"]["gem_version"]).to eql("1.2.3")
    end

    describe "sources" do
      it "should have no sources" do
        expect(subject.sources).to be_empty
      end

      it "should add sources" do
        subject.add_source("foo")
        expect(subject.sources).to eql(["foo"])
      end

      it "should de-dup sources" do
        subject.add_source("foo")
        subject.add_source("foo")
        expect(subject.sources).to eql(["foo"])
      end

      it "can remove sources" do
        subject.add_source("foo")
        subject.remove_source("foo")
        expect(subject.sources).to be_empty
      end
    end
  end

  context "with an old-style file" do
    before do
      data = {
        "installed" => ["foo"],
      }

      path.open("w+") do |f|
        f.write(JSON.dump(data))
      end
    end

    it "should have the right installed plugins" do
      plugins = subject.installed_plugins
      expect(plugins.keys).to eql(["foo"])
      expect(plugins["foo"]["ruby_version"]).to eql("0")
      expect(plugins["foo"]["vagrant_version"]).to eql("0")
    end
  end

  context "with parse errors" do
    before do
      path.open("w+") do |f|
        f.write("I'm not json")
      end
    end

    it "should raise a VagrantError" do
      expect { subject }.
        to raise_error(Vagrant::Errors::PluginStateFileParseError)
    end
  end

  context "go plugin usage" do
    describe "#add_go_plugin" do
      it "should add plugin to list of installed go plugins" do
        subject.add_go_plugin("foo", source: "http://localhost/foo.zip")
        expect(subject.installed_go_plugins).to include("foo")
      end

      it "should update source when added again" do
        subject.add_go_plugin("foo", source: "http://localhost/foo.zip")
        expect(subject.installed_go_plugins["foo"]["source"]).to eq("http://localhost/foo.zip")
        subject.add_go_plugin("foo", source: "http://localhost/foo1.zip")
        expect(subject.installed_go_plugins["foo"]["source"]).to eq("http://localhost/foo1.zip")
      end
    end

    describe "#remove_go_plugin" do
      before do
        subject.add_go_plugin("foo", source: "http://localhost/foo.zip")
      end

      it "should remove the installed plugin" do
        subject.remove_go_plugin("foo")
        expect(subject.installed_go_plugins).not_to include("foo")
      end

      it "should remove plugin not installed" do
        subject.remove_go_plugin("foo")
        expect(subject.installed_go_plugins).not_to include("foo")
        subject.remove_go_plugin("foo")
        expect(subject.installed_go_plugins).not_to include("foo")
      end
    end

    describe "#has_go_plugin?" do
      before do
        subject.add_go_plugin("foo", source: "http://localhost/foo.zip")
      end

      it "should return true when plugin is installed" do
        expect(subject.has_go_plugin?("foo")).to be_truthy
      end

      it "should return false when plugin is not installed" do
        expect(subject.has_go_plugin?("fee")).to be_falsey
      end

      it "should allow symbol names" do
        expect(subject.has_go_plugin?(:foo)).to be_truthy
      end
    end
  end
end
