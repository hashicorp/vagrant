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
end
