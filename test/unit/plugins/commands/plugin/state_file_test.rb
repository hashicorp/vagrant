require "json"
require "pathname"

require File.expand_path("../../../../base", __FILE__)

describe VagrantPlugins::CommandPlugin::StateFile do
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

  it "should have no plugins without saving some" do
    expect(subject.installed_plugins).to be_empty
  end

  it "should have plugins when saving" do
    subject.add_plugin("foo")

    instance = described_class.new(path)
    expect(instance.installed_plugins).to eql(["foo"])
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
    expect(instance.installed_plugins).to eql(["foo"])
  end
end
