require File.expand_path("../../base", __FILE__)

require "pathname"
require 'tempfile'

describe Vagrant::BoxCollection do
  include_context "unit"

  let(:box_class)   { Vagrant::Box }
  let(:environment) { isolated_environment }
  let(:instance)    { described_class.new(environment.boxes_dir) }

  it "should tell us the directory it is using" do
    instance.directory.should == environment.boxes_dir
  end

  describe "adding" do
    it "should add a valid box to the system" do
      box_path = environment.box2_file(:virtualbox)

      # Add the box
      box = instance.add(box_path, "foo", :virtualbox)
      box.should be_kind_of(box_class)
      box.name.should == "foo"
      box.provider.should == :virtualbox

      # Verify we can find it as well
      box = instance.find("foo", :virtualbox)
      box.should_not be_nil
    end

    it "should add a box without specifying a provider" do
      box_path = environment.box2_file(:vmware)

      # Add the box
      box = instance.add(box_path, "foo")
      box.should be_kind_of(box_class)
      box.name.should == "foo"
      box.provider.should == :vmware
    end

    it "should add a V1 box" do
      # Create a V1 box.
      box_path = environment.box1_file

      # Add the box
      box = instance.add(box_path, "foo")
      box.should be_kind_of(box_class)
      box.name.should == "foo"
      box.provider.should == :virtualbox
    end

    it "should raise an exception if the box already exists" do
      prev_box_name = "foo"
      prev_box_provider = :virtualbox

      # Create the box we're adding
      environment.box2(prev_box_name, prev_box_provider)

      # Attempt to add the box with the same name
      box_path = environment.box2_file(prev_box_provider)
      expect { instance.add(box_path, prev_box_name, prev_box_provider) }.
        to raise_error(Vagrant::Errors::BoxAlreadyExists)
    end

    it "should replace the box if force is specified" do
      prev_box_name = "foo"
      prev_box_provider = :vmware

      # Setup the environment with the box pre-added
      environment.box2(prev_box_name, prev_box_provider)

      # Attempt to add the box with the same name
      box_path = environment.box2_file(prev_box_provider, metadata: { "replaced" => "yes" })
      box = instance.add(box_path, prev_box_name, nil, true)
      box.metadata["replaced"].should == "yes"
    end

    it "should raise an exception if the box already exists and no provider is given" do
      # Create some box file
      box_name = "foo"
      box_path = environment.box2_file(:vmware)

      # Add it once, successfully
      expect { instance.add(box_path, box_name) }.to_not raise_error

      # Add it again, and fail!
      expect { instance.add(box_path, box_name) }.
        to raise_error(Vagrant::Errors::BoxAlreadyExists)
    end

    it "should raise an exception if you're attempting to add a box that exists as a V1 box" do
      prev_box_name = "foo"

      # Create the V1 box
      environment.box1(prev_box_name)

      # Attempt to add some V2 box with the same name
      box_path = environment.box2_file(:vmware)
      expect { instance.add(box_path, prev_box_name) }.
        to raise_error(Vagrant::Errors::BoxUpgradeRequired)
    end

    it "should raise an exception and not add the box if the provider doesn't match" do
      box_name      = "foo"
      good_provider = :virtualbox
      bad_provider  = :vmware

      # Create a VirtualBox box file
      box_path = environment.box2_file(good_provider)

      # Add the box but with an invalid provider, verify we get the proper
      # error.
      expect { instance.add(box_path, box_name, bad_provider) }.
        to raise_error(Vagrant::Errors::BoxProviderDoesntMatch)

      # Verify the box doesn't exist
      instance.find(box_name, bad_provider).should be_nil
    end

    it "should raise an exception if you add an invalid box file" do
      # Tar Header information
      CHECKSUM_OFFSET = 148
      CHECKSUM_LENGTH = 8

      Tempfile.new(['vagrant_testing', '.tar']) do |f|
        # Corrupt the tar by writing over the checksum field
        f.seek(CHECKSUM_OFFSET)
        f.write("\0"*CHECKSUM_LENGTH)
        f.close

        expect { instance.add(path, "foo", :virtualbox) }.
          to raise_error(Vagrant::Errors::BoxUnpackageFailure)
      end
    end
  end

  describe "listing all" do
    it "should return an empty array when no boxes are there" do
      instance.all.should == []
    end

    it "should return the boxes and their providers" do
      # Create some boxes
      environment.box2("foo", :virtualbox)
      environment.box2("foo", :vmware)
      environment.box2("bar", :ec2)

      # Verify some output
      results = instance.all
      results.length.should == 3
      results.include?(["foo", :virtualbox]).should be
      results.include?(["foo", :vmware]).should be
      results.include?(["bar", :ec2]).should be
    end

    it "should return V1 boxes as well" do
      # Create some boxes, including a V1 box
      environment.box1("bar")
      environment.box2("foo", :vmware)

      # Verify some output
      results = instance.all.sort
      results.should == [["bar", :virtualbox, :v1], ["foo", :vmware]]
    end

    it 'does not raise an exception when a file appears in the boxes dir' do
      Tempfile.new('a_file', environment.boxes_dir)
      expect { instance.all }.to_not raise_error
    end
  end

  describe "finding" do
    it "should return nil if the box does not exist" do
      instance.find("foo", :i_dont_exist).should be_nil
    end

    it "should return a box if the box does exist" do
      # Create the "box"
      environment.box2("foo", :virtualbox)

      # Actual test
      result = instance.find("foo", :virtualbox)
      result.should_not be_nil
      result.should be_kind_of(box_class)
      result.name.should == "foo"
    end

    it "should throw an exception if it is a v1 box" do
      # Create a V1 box
      environment.box1("foo")

      # Test!
      expect { instance.find("foo", :virtualbox) }.
        to raise_error(Vagrant::Errors::BoxUpgradeRequired)
    end

    it "should return nil if there is a V1 box but we're looking for another provider" do
      # Create a V1 box
      environment.box1("foo")

      # Test
      instance.find("foo", :another_provider).should be_nil
    end
  end

  describe "upgrading" do
    it "should upgrade a V1 box to V2" do
      # Create a V1 box
      environment.box1("foo")

      # Verify that only a V1 box exists
      expect { instance.find("foo", :virtualbox) }.
        to raise_error(Vagrant::Errors::BoxUpgradeRequired)

      # Upgrade the box
      instance.upgrade("foo").should be

      # Verify the box exists
      box = instance.find("foo", :virtualbox)
      box.should_not be_nil
      box.name.should == "foo"
    end

    it "should raise a BoxNotFound exception if a non-existent box is upgraded" do
      expect { instance.upgrade("i-dont-exist") }.
        to raise_error(Vagrant::Errors::BoxNotFound)
    end

    it "should return true if we try to upgrade a V2 box" do
      # Create a V2 box
      environment.box2("foo", :vmware)

      instance.upgrade("foo").should be
    end
  end
end
