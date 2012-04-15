require File.expand_path("../../../base", __FILE__)

describe Vagrant::Plugin::V1 do
  after(:each) do
    # We want to make sure that the registered plugins remains empty
    # after each test.
    described_class.registered.clear
  end

  it "should be able to set and get the name" do
    plugin = Class.new(described_class) do
      name "foo"
    end

    plugin.name.should == "foo"
  end

  it "should be able to set and get the description" do
    plugin = Class.new(described_class) do
      description "bar"
    end

    plugin.description.should == "bar"
  end

  it "should have no registered plugins" do
    described_class.registered.should be_empty
  end

  it "should register a plugin when a name is set" do
    plugin = Class.new(described_class) do
      name "foo"
    end

    described_class.registered.should == [plugin]
  end

  it "should register a plugin only once" do
    plugin = Class.new(described_class) do
      name "foo"
      name "bar"
    end

    described_class.registered.should == [plugin]
  end
end
