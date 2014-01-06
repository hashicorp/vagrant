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

  after do
    path.unlink if path.file?
  end

  subject { described_class.new(path) }

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
        expect(subject.installed_plugins).to eql(["foo"])
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
