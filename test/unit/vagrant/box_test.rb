require File.expand_path("../../base", __FILE__)

require "pathname"

describe Vagrant::Box do
  include_context "unit"

  let(:environment)   { isolated_environment }

  let(:box_collection) { Vagrant::BoxCollection.new(environment.boxes_dir) }

  let(:name)          { "foo" }
  let(:provider)      { :virtualbox }
  let(:directory)     { environment.box2("foo", :virtualbox) }
  let(:instance)      { described_class.new(name, provider, directory) }

  subject { described_class.new(name, provider, directory) }

  it "provides the name" do
    instance.name.should == name
  end

  it "provides the provider" do
    instance.provider.should == provider
  end

  it "provides the directory" do
    instance.directory.should == directory
  end

  it "provides the metadata associated with a box" do
    data = { "foo" => "bar" }

    # Write the metadata
    directory.join("metadata.json").open("w") do |f|
      f.write(JSON.generate(data))
    end

    # Verify the metadata
    instance.metadata.should == data
  end

  context "without a metadata file" do
    before :each do
      directory.join("metadata.json").delete
    end

    it "should raise an exception" do
      expect { subject }.
        to raise_error(Vagrant::Errors::BoxMetadataFileNotFound)
    end
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
      # Get the instance so that it is instantiated
      box = instance

      # Delete the directory
      directory.rmtree

      # Destroy it
      box.destroy!.should be
    end
  end

  describe "repackaging" do
    it "should repackage the box" do
      test_file_contents = "hello, world!"

      # Put a file in the box directory to verify it is packaged properly
      # later.
      directory.join("test_file").open("w") do |f|
        f.write(test_file_contents)
      end

      # Repackage our box to some temporary directory
      box_output_path = temporary_dir.join("package.box")
      instance.repackage(box_output_path).should be

      # Let's now add this box again under a different name, and then
      # verify that we get the proper result back.
      new_box = box_collection.add(box_output_path, "foo2")
      new_box.directory.join("test_file").read.should == test_file_contents
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
