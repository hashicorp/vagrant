require File.expand_path("../../base", __FILE__)

require "pathname"

describe Vagrant::Box2 do
  include_context "unit"

  let(:name)          { "foo" }
  let(:provider)      { :virtualbox }
  let(:directory)     { temporary_dir }
  let(:instance)      { described_class.new(name, provider, directory) }

  it "provides the name" do
    instance.name.should == name
  end

  it "provides the provider" do
    instance.provider.should == provider
  end

  it "provides the directory" do
    instance.directory.should == directory
  end

  describe "destroying" do
    it "should destroy an existing box" do
      # Verify that our "box" exists
      directory.exist?.should be

      # Destroy it
      instance.destroy!.should be

      # Verify that it is "destroyed"
      directory.exist?.should_not be
    end

    it "should not error destroying a non-existent box" do
      # Delete the directory
      directory.rmtree

      # Destroy it
      instance.destroy!.should be
    end
  end

  describe "comparison and ordering" do
    it "should be equal if the name and provider match" do
      a = described_class.new("a", :foo, directory)
      b = described_class.new("a", :foo, directory)

      a.should == b
    end

    it "should not be equal if the name and provider do not match" do
      a = described_class.new("a", :foo, directory)
      b = described_class.new("b", :foo, directory)

      a.should_not == b
    end

    it "should sort them in order of name then provider" do
      a = described_class.new("a", :foo, directory)
      b = described_class.new("b", :foo, directory)
      c = described_class.new("c", :foo2, directory)

      [c, a, b].sort.should == [a, b, c]
    end
  end
end
