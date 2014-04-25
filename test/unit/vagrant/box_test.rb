require File.expand_path("../../base", __FILE__)

require "pathname"
require "stringio"
require "tempfile"

require "vagrant/box_metadata"

describe Vagrant::Box do
  include_context "unit"

  let(:environment)   { isolated_environment }

  let(:box_collection) { Vagrant::BoxCollection.new(environment.boxes_dir) }

  let(:name)          { "foo" }
  let(:provider)      { :virtualbox }
  let(:version)       { "1.0" }
  let(:directory)     { environment.box3("foo", "1.0", :virtualbox) }
  subject             { described_class.new(name, provider, version, directory) }

  describe '#metadata_url' do
    subject { super().metadata_url }
    it { should be_nil }
  end

  it "provides the name" do
    expect(subject.name).to eq(name)
  end

  it "provides the provider" do
    expect(subject.provider).to eq(provider)
  end

  it "provides the directory" do
    expect(subject.directory).to eq(directory)
  end

  it "provides the metadata associated with a box" do
    data = { "foo" => "bar" }

    # Write the metadata
    directory.join("metadata.json").open("w") do |f|
      f.write(JSON.generate(data))
    end

    # Verify the metadata
    expect(subject.metadata).to eq(data)
  end

  context "with a metadata URL" do
    subject do
      described_class.new(
        name, provider, version, directory,
        metadata_url: "foo")
    end

    describe '#metadata_url' do
      subject { super().metadata_url }
      it { should eq("foo") }
    end
  end

  context "with a corrupt metadata file" do
    before do
      directory.join("metadata.json").open("w") do |f|
        f.write("")
      end
    end

    it "should raise an exception" do
      expect { subject }.
        to raise_error(Vagrant::Errors::BoxMetadataCorrupted)
    end
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

  context "#has_update?" do
    subject do
      described_class.new(
        name, provider, version, directory,
        metadata_url: "foo")
    end

    it "raises an exception if no metadata_url is set" do
      subject = described_class.new(
        name, provider, version, directory)

      expect { subject.has_update?("> 0") }.
        to raise_error(Vagrant::Errors::BoxUpdateNoMetadata)
    end

    it "returns nil if there is no update" do
      metadata = Vagrant::BoxMetadata.new(StringIO.new(<<-RAW))
      {
        "name": "foo",
        "versions": [
          { "version": "1.0" }
        ]
      }
      RAW

      subject.stub(load_metadata: metadata)

      expect(subject.has_update?).to be_nil
    end

    it "returns the updated box info if there is an update available" do
      metadata = Vagrant::BoxMetadata.new(StringIO.new(<<-RAW))
      {
        "name": "foo",
        "versions": [
          {
            "version": "1.0"
          },
          {
            "version": "1.1",
            "providers": [
              {
                "name": "virtualbox",
                "url": "bar"
              }
            ]
          }
        ]
      }
      RAW

      subject.stub(load_metadata: metadata)

      result = subject.has_update?
      expect(result).to_not be_nil

      expect(result[0]).to be_kind_of(Vagrant::BoxMetadata)
      expect(result[1]).to be_kind_of(Vagrant::BoxMetadata::Version)
      expect(result[2]).to be_kind_of(Vagrant::BoxMetadata::Provider)

      expect(result[0].name).to eq("foo")
      expect(result[1].version).to eq("1.1")
      expect(result[2].url).to eq("bar")
    end

    it "returns the updated box info within constraints" do
      metadata = Vagrant::BoxMetadata.new(StringIO.new(<<-RAW))
      {
        "name": "foo",
        "versions": [
          {
            "version": "1.0"
          },
          {
            "version": "1.1",
            "providers": [
              {
                "name": "virtualbox",
                "url": "bar"
              }
            ]
          },
          {
            "version": "1.4",
            "providers": [
              {
                "name": "virtualbox",
                "url": "bar"
              }
            ]
          }
        ]
      }
      RAW

      subject.stub(load_metadata: metadata)

      result = subject.has_update?(">= 1.1, < 1.4")
      expect(result).to_not be_nil

      expect(result[0]).to be_kind_of(Vagrant::BoxMetadata)
      expect(result[1]).to be_kind_of(Vagrant::BoxMetadata::Version)
      expect(result[2]).to be_kind_of(Vagrant::BoxMetadata::Provider)

      expect(result[0].name).to eq("foo")
      expect(result[1].version).to eq("1.1")
      expect(result[2].url).to eq("bar")
    end
  end

  context "#in_use?" do
    let(:index) { [] }

    def new_entry(name, provider, version)
      Vagrant::MachineIndex::Entry.new.tap do |entry|
        entry.extra_data["box"] = {
          "name" => name,
          "provider" => provider,
          "version" => version,
        }
      end
    end

    it "returns nil if the index has no matching entries" do
      index << new_entry("foo", "bar", "1.0")
      index << new_entry("foo", "baz", "1.2")

      expect(subject).to_not be_in_use(index)
    end

    it "returns matching entries if they exist" do
      matching = new_entry(name, provider.to_s, version)
      index << new_entry("foo", "bar", "1.0")
      index << matching
      index << new_entry("foo", "baz", "1.2")

      expect(subject.in_use?(index)).to eq([matching])
    end
  end

  context "#load_metadata" do
    let(:metadata_url) do
      Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo",
          "description": "bar"
        }
        RAW
        f.close
      end
    end

    subject do
      described_class.new(
        name, provider, version, directory,
        metadata_url: metadata_url.path)
    end

    it "loads the url and returns the data" do
      result = subject.load_metadata
      expect(result.name).to eq("foo")
      expect(result.description).to eq("bar")
    end

    it "raises an error if the download failed" do
      dl = double("downloader")
      Vagrant::Util::Downloader.stub(new: dl)
      dl.should_receive(:download!).and_raise(
        Vagrant::Errors::DownloaderError.new(message: "foo"))

      expect { subject.load_metadata }.
        to raise_error(Vagrant::Errors::BoxMetadataDownloadError)
    end
  end

  describe "destroying" do
    it "should destroy an existing box" do
      # Verify that our "box" exists
      expect(directory.exist?).to be

      # Destroy it
      expect(subject.destroy!).to be

      # Verify that it is "destroyed"
      expect(directory.exist?).not_to be
    end

    it "should not error destroying a non-existent box" do
      # Get the subject so that it is instantiated
      box = subject

      # Delete the directory
      directory.rmtree

      # Destroy it
      expect(box.destroy!).to be
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
      expect(subject.repackage(box_output_path)).to be_true

      # Let's now add this box again under a different name, and then
      # verify that we get the proper result back.
      new_box = box_collection.add(box_output_path, "foo2", "1.0")
      expect(new_box.directory.join("test_file").read).to eq(test_file_contents)
    end
  end

  describe "comparison and ordering" do
    it "should be equal if the name, provider, version match" do
      a = described_class.new("a", :foo, "1.0", directory)
      b = described_class.new("a", :foo, "1.0", directory)

      expect(a).to eq(b)
    end

    it "should not be equal if name doesn't match" do
      a = described_class.new("a", :foo, "1.0", directory)
      b = described_class.new("b", :foo, "1.0", directory)

      expect(a).to_not eq(b)
    end

    it "should not be equal if provider doesn't match" do
      a = described_class.new("a", :foo, "1.0", directory)
      b = described_class.new("a", :bar, "1.0", directory)

      expect(a).to_not eq(b)
    end

    it "should not be equal if version doesn't match" do
      a = described_class.new("a", :foo, "1.0", directory)
      b = described_class.new("a", :foo, "1.1", directory)

      expect(a).to_not eq(b)
    end

    it "should sort them in order of name, version, provider" do
      a = described_class.new("a", :foo, "1.0", directory)
      b = described_class.new("a", :foo2, "1.0", directory)
      c = described_class.new("a", :foo2, "1.1", directory)
      d = described_class.new("b", :foo2, "1.0", directory)

      expect([d, c, a, b].sort).to eq([a, b, c, d])
    end
  end
end
