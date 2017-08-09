require File.expand_path("../../base", __FILE__)

require "pathname"
require 'tempfile'

describe Vagrant::BoxCollection, :skip_windows do
  include_context "unit"

  let(:box_class)   { Vagrant::Box }
  let(:environment) { isolated_environment }

  subject { described_class.new(environment.boxes_dir) }

  it "should tell us the directory it is using" do
    expect(subject.directory).to eq(environment.boxes_dir)
  end

  describe "#all" do
    it "should return an empty array when no boxes are there" do
      expect(subject.all).to eq([])
    end

    it "should return the boxes and their providers" do
      # Create some boxes
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "1.0", :vmware)
      environment.box3("bar", "0", :ec2)
      environment.box3("foo-VAGRANTSLASH-bar", "1.0", :virtualbox)
      environment.box3("foo-VAGRANTCOLON-colon", "1.0", :virtualbox)

      # Verify some output
      results = subject.all
      expect(results.length).to eq(5)
      expect(results.include?(["foo", "1.0", :virtualbox])).to be
      expect(results.include?(["foo", "1.0", :vmware])).to be
      expect(results.include?(["bar", "0", :ec2])).to be
      expect(results.include?(["foo/bar", "1.0", :virtualbox])).to be
      expect(results.include?(["foo:colon", "1.0", :virtualbox])).to be
    end

    it 'does not raise an exception when a file appears in the boxes dir' do
      Tempfile.open('vagrant-a_file', environment.boxes_dir) do
        expect { subject.all }.to_not raise_error
      end
    end

    context "with multiple versions of the same box" do
      before do
        environment.box3("foo", "1.0", :virtualbox)
        environment.box3("foo", "2.0.3", :virtualbox)
        environment.box3("foo", "2.0.4", :virtualbox)
        environment.box3("foo", "10.3", :virtualbox)
        environment.box3("foo", "1.0", :vmware)
        environment.box3("foo", "0.4.3", :vmware)
        environment.box3("foo", "2.0.1", :vmware)
        environment.box3("foo", "2.0.2.dev", :vmware)
        environment.box3("foo", "2.0.2", :vmware)
        environment.box3("bar", "20161203.2", :ec2)
        environment.box3("bar", "20161203.2.3", :ec2)
        environment.box3("bar", "20151102.0.0", :ec2)
        environment.box3("foo-VAGRANTSLASH-bar", "1.0", :virtualbox)
        environment.box3("foo-VAGRANTCOLON-colon", "1.0", :virtualbox)
      end

      it "should sort boxes by name" do
        result = subject.all.map(&:first).uniq
        expect(result).to eq(["bar", "foo", "foo/bar", "foo:colon"])
      end

      it "should group boxes by provider" do
        expect do
          current = ""
          seen_pairs = {}
          subject.all.each do |box_info|
            box_key = "#{box_info[0]}_#{box_info[2]}"
            if current != box_key
              if seen_pairs[box_key]
                raise KeyError.new("Box/provider pair already seen. Invalid sort!")
              else
                current = box_key
                seen_pairs[box_key] = true
              end
            end
          end
        end.not_to raise_error
      end

      it "should sort boxes by version" do
        box_list = subject.all.find_all do |box_info|
          box_info[0] == "foo" && box_info[2].to_s == "virtualbox"
        end
        result = box_list.map{|box_info| box_info[1]}
        expect(result).to eq([
          "1.0",
          "2.0.3",
          "2.0.4",
          "10.3"
        ])
      end

      it "should sort boxes with pre-release versions" do
        box_list = subject.all.find_all do |box_info|
          box_info[0] == "foo" && box_info[2].to_s == "vmware"
        end
        result = box_list.map{|box_info| box_info[1]}
        expect(result).to eq([
          "0.4.3",
          "1.0",
          "2.0.1",
          "2.0.2.dev",
          "2.0.2"
        ])
      end
    end
  end

  describe "#clean" do
    it "removes the directory if no other versions of the box exists" do
      # Create a few boxes, immediately destroy them
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "1.0", :vmware)

      # Delete them all
      subject.all.each do |parts|
        subject.find(parts[0], parts[2], ">= 0").destroy!
      end

      # Cleanup
      subject.clean("foo")

      # Make sure the whole directory is empty
      expect(environment.boxes_dir.children).to be_empty
    end

    it "doesn't remove the directory if a provider exists" do
      # Create a few boxes, immediately destroy them
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "1.0", :vmware)

      # Delete them all
      subject.find("foo", :virtualbox, ">= 0").destroy!

      # Cleanup
      subject.clean("foo")

      # Make sure the whole directory is not empty
      expect(environment.boxes_dir.children).to_not be_empty

      # Make sure the results still exist
      results = subject.all
      expect(results.length).to eq(1)
      expect(results.include?(["foo", "1.0", :vmware])).to be
    end

    it "doesn't remove the directory if a version exists" do
      # Create a few boxes, immediately destroy them
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "1.2", :virtualbox)

      # Delete them all
      subject.find("foo", :virtualbox, ">= 1.1").destroy!

      # Cleanup
      subject.clean("foo")

      # Make sure the whole directory is not empty
      expect(environment.boxes_dir.children).to_not be_empty

      # Make sure the results still exist
      results = subject.all
      expect(results.length).to eq(1)
      expect(results.include?(["foo", "1.0", :virtualbox])).to be
    end
  end

  describe "#find" do
    it "returns nil if the box does not exist" do
      expect(subject.find("foo", :i_dont_exist, ">= 0")).to be_nil
    end

    it "returns a box if the box does exist" do
      # Create the "box"
      environment.box3("foo", "0", :virtualbox)

      # Actual test
      result = subject.find("foo", :virtualbox, ">= 0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.metadata_url).to be_nil
    end

    it "returns a box if the box does exist, with no constraints" do
      # Create the "box"
      environment.box3("foo", "0", :virtualbox)

      # Actual test
      result = subject.find("foo", :virtualbox, nil)
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.metadata_url).to be_nil
    end

    it "sets a metadata URL if it has one" do
      # Create the "box"
      environment.box3("foo", "0", :virtualbox,
        metadata_url: "foourl")

      # Actual test
      result = subject.find("foo", :virtualbox, ">= 0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.metadata_url).to eq("foourl")
    end

    it "sets the metadata URL to an authenticated URL if it has one" do
      hook    = double("hook")
      subject = described_class.new(environment.boxes_dir, hook: hook)

      # Create the "box"
      environment.box3("foo", "0", :virtualbox,
        metadata_url: "foourl")

      expect(hook).to receive(:call).with(any_args) { |name, env|
        expect(name).to eq(:authenticate_box_url)
        expect(env[:box_urls]).to eq(["foourl"])
        true
      }.and_return(box_urls: ["bar"])

      # Actual test
      result = subject.find("foo", :virtualbox, ">= 0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.metadata_url).to eq("bar")
    end

    it "returns latest version matching constraint" do
      # Create the "box"
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "1.5", :virtualbox)

      # Actual test
      result = subject.find("foo", :virtualbox, ">= 0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.version).to eq("1.5")
    end

    it "can satisfy complex constraints" do
      # Create the "box"
      environment.box3("foo", "0.1", :virtualbox)
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "2.1", :virtualbox)

      # Actual test
      result = subject.find("foo", :virtualbox, ">= 0.9, < 1.5")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.version).to eq("1.0")
    end

    it "handles prerelease versions" do
      # Create the "box"
      environment.box3("foo", "0.1.0-alpha.1", :virtualbox)
      environment.box3("foo", "0.1.0-alpha.2", :virtualbox)

      # Actual test
      result = subject.find("foo", :virtualbox, ">= 0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(box_class)
      expect(result.name).to eq("foo")
      expect(result.version).to eq("0.1.0-alpha.2")
    end

    it "returns nil if a box's constraints can't be satisfied" do
      # Create the "box"
      environment.box3("foo", "0.1", :virtualbox)
      environment.box3("foo", "1.0", :virtualbox)
      environment.box3("foo", "2.1", :virtualbox)

      # Actual test
      result = subject.find("foo", :virtualbox, "> 1.0, < 1.5")
      expect(result).to be_nil
    end

    context "with multiple versions of the same box" do
      before do
        environment.box3("foo", "1.0", :virtualbox)
        environment.box3("foo", "2.0.3", :virtualbox)
        environment.box3("foo", "2.0.4", :virtualbox)
        environment.box3("foo", "10.3", :virtualbox)
        environment.box3("foo", "1.0", :vmware)
        environment.box3("foo", "0.4.3", :vmware)
        environment.box3("foo", "2.0.1", :vmware)
        environment.box3("foo", "2.0.2.dev", :vmware)
        environment.box3("foo", "2.0.2", :vmware)
        environment.box3("bar", "20161203.2", :ec2)
        environment.box3("bar", "20161203.2.3", :ec2)
        environment.box3("bar", "20151102.0.0", :ec2)
        environment.box3("foo-VAGRANTSLASH-bar", "1.0", :virtualbox)
        environment.box3("foo-VAGRANTCOLON-colon", "1.0", :virtualbox)
      end

      it "should return expected latest version" do
        result = subject.find("foo", :virtualbox, "> 2, < 3")
        expect(result.version).to eq("2.0.4")
      end

      it "should sort boxes with pre-release versions" do
        result = subject.find("foo", :vmware, "> 2, < 3")
        expect(result.version).to eq("2.0.2")
      end
    end
  end

  describe "#add" do
    it "should add a valid box to the system" do
      box_path = environment.box2_file(:virtualbox)

      # Add the box
      box = subject.add(box_path, "foo", "1.0", providers: :virtualbox)
      expect(box).to be_kind_of(box_class)
      expect(box.name).to eq("foo")
      expect(box.provider).to eq(:virtualbox)

      # Verify we can find it as well
      expect(subject.find("foo", :virtualbox, "1.0")).to_not be_nil
    end

    it "should add a box with a name with '/' in it" do
      box_path = environment.box2_file(:virtualbox)

      # Add the box
      box = subject.add(box_path, "foo/bar", "1.0")
      expect(box).to be_kind_of(box_class)
      expect(box.name).to eq("foo/bar")
      expect(box.provider).to eq(:virtualbox)

      # Verify we can find it as well
      expect(subject.find("foo/bar", :virtualbox, "1.0")).to_not be_nil
    end

    it "should add a box without specifying a provider" do
      box_path = environment.box2_file(:vmware)

      # Add the box
      box = subject.add(box_path, "foo", "1.0")
      expect(box).to be_kind_of(box_class)
      expect(box.name).to eq("foo")
      expect(box.provider).to eq(:vmware)
    end

    it "should store a metadata URL" do
      box_path = environment.box2_file(:virtualbox)

      subject.add(
        box_path, "foo", "1.0",
        metadata_url: "bar")

      box = subject.find("foo", :virtualbox, "1.0")
      expect(box.metadata_url).to eq("bar")
    end

    it "should add a V1 box" do
      # Create a V1 box.
      box_path = environment.box1_file

      # Add the box
      box = subject.add(box_path, "foo", "1.0")
      expect(box).to be_kind_of(box_class)
      expect(box.name).to eq("foo")
      expect(box.provider).to eq(:virtualbox)
    end

    it "should raise an exception if the box already exists" do
      prev_box_name = "foo"
      prev_box_provider = :virtualbox
      prev_box_version = "1.0"

      # Create the box we're adding
      environment.box3(prev_box_name, "1.0", prev_box_provider)

      # Attempt to add the box with the same name
      box_path = environment.box2_file(prev_box_provider)
      expect {
        subject.add(box_path, prev_box_name,
                    prev_box_version, providers: prev_box_provider)
      }.to raise_error(Vagrant::Errors::BoxAlreadyExists)
    end

    it "should replace the box if force is specified" do
      prev_box_name = "foo"
      prev_box_provider = :vmware
      prev_box_version = "1.0"

      # Setup the environment with the box pre-added
      environment.box3(prev_box_name, prev_box_version, prev_box_provider)

      # Attempt to add the box with the same name
      box_path = environment.box2_file(prev_box_provider, metadata: { "replaced" => "yes" })
      box = subject.add(box_path, prev_box_name, prev_box_version, force: true)
      expect(box.metadata["replaced"]).to eq("yes")
    end

    it "should raise an exception if the box already exists and no provider is given" do
      # Create some box file
      box_name = "foo"
      box_path = environment.box2_file(:vmware)

      # Add it once, successfully
      expect { subject.add(box_path, box_name, "1.0") }.to_not raise_error

      # Add it again, and fail!
      expect { subject.add(box_path, box_name, "1.0") }.
        to raise_error(Vagrant::Errors::BoxAlreadyExists)
    end

    it "should raise an exception and not add the box if the provider doesn't match" do
      box_name      = "foo"
      good_provider = :virtualbox
      bad_provider  = :vmware

      # Create a VirtualBox box file
      box_path = environment.box2_file(good_provider)

      # Add the box but with an invalid provider, verify we get the proper
      # error.
      expect { subject.add(box_path, box_name, "1.0", providers: bad_provider) }.
        to raise_error(Vagrant::Errors::BoxProviderDoesntMatch)

      # Verify the box doesn't exist
      expect(subject.find(box_name, bad_provider, "1.0")).to be_nil
    end

    it "should raise an exception if you add an invalid box file" do
      # Tar Header information
      CHECKSUM_OFFSET = 148
      CHECKSUM_LENGTH = 8

      Tempfile.open(['vagrant-testing', '.tar']) do |f|
        f.binmode

        # Corrupt the tar by writing over the checksum field
        f.seek(CHECKSUM_OFFSET)
        f.write("\0"*CHECKSUM_LENGTH)
        f.close

        expect { subject.add(f.path, "foo", "1.0") }.
          to raise_error(Vagrant::Errors::BoxUnpackageFailure)
      end
    end
  end

  describe "#upgrade_v1_1_v1_5" do
    let(:boxes_dir) { environment.boxes_dir }

    before do
      # Create all the various box directories
      @foo_path    = environment.box2("foo", "virtualbox")
      @vbox_path   = environment.box2("precise64", "virtualbox")
      @vmware_path = environment.box2("precise64", "vmware")
      @v1_path     = environment.box("v1box")
    end

    it "upgrades the boxes" do
      subject.upgrade_v1_1_v1_5

      # The old paths should not exist anymore
      expect(@foo_path).to_not exist
      expect(@vbox_path).to_not exist
      expect(@vmware_path).to_not exist
      expect(@v1_path.join("box.ovf")).to_not exist

      # New paths should exist
      foo_path = boxes_dir.join("foo", "0", "virtualbox")
      vbox_path = boxes_dir.join("precise64", "0", "virtualbox")
      vmware_path = boxes_dir.join("precise64", "0", "vmware")
      v1_path = boxes_dir.join("v1box", "0", "virtualbox")

      expect(foo_path).to exist
      expect(vbox_path).to exist
      expect(vmware_path).to exist
      expect(v1_path).to exist
    end
  end
end
