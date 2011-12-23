require File.expand_path("../../base", __FILE__)

require 'pathname'

describe Vagrant::DataStore do
  include_context "unit"

  let(:db_file) do
    # We create a tempfile and force an explicit close/unlink
    # but save the path so that we can re-use it multiple times
    temp = Tempfile.new("vagrant")
    result = Pathname.new(temp.path)
    temp.close
    temp.unlink

    result
  end

  let(:instance)    { described_class.new(db_file) }

  it "initializes a new DB file" do
    instance[:data] = true
    instance.commit
    instance[:data].should == true

    test = described_class.new(db_file)
    test[:data].should == true
  end

  it "initializes empty if the file contains invalid data" do
    db_file.open("w+") { |f| f.write("NOPE!") }
    described_class.new(db_file).should be_empty
  end

  it "initializes empty if the file doesn't exist" do
    described_class.new("NOPENOPENOPENOPENPEPEPEPE").should be_empty
  end

  it "raises an error if the path given is a directory" do
    db_file.delete if db_file.exist?
    db_file.mkdir

    expect { described_class.new(db_file) }.
      to raise_error(Vagrant::Errors::DotfileIsDirectory)
  end

  it "cleans nil and empties when committing" do
    instance[:data] = { :bar => nil }
    instance[:another] = {}
    instance.commit

    # The instance is now empty because the data was nil
    instance.should be_empty
  end

  it "deletes the data file if the store is empty when saving" do
    instance[:data] = true
    instance.commit

    another = described_class.new(db_file)
    another[:data] = nil
    another.commit

    # The file should no longer exist
    db_file.should_not be_exist
  end
end
