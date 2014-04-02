require File.expand_path("../../base", __FILE__)

require "vagrant/box_metadata"

describe Vagrant::BoxMetadata do
  include_context "unit"

  let(:raw) do
    <<-RAW
      {
        "name": "foo",
        "description": "bar",
        "versions": [
          {
            "version": "1.0.0",
            "providers": [
              { "name": "virtualbox" },
              { "name": "vmware" }
            ]
          },
          {
            "version": "1.1.5",
            "providers": [
              { "name": "virtualbox" }
            ]
          },
          {
            "version": "1.1.0",
            "providers": [
              { "name": "virtualbox" },
              { "name": "vmware" }
            ]
          }
        ]
      }
    RAW
  end

  subject { described_class.new(raw) }

  describe '#name' do
    subject { super().name }
    it { should eq("foo") }
  end

  describe '#description' do
    subject { super().description }
    it { should eq("bar") }
  end

  context "with poorly formatted JSON" do
    let(:raw) {
      <<-RAW
      { "name": "foo", }
      RAW
    }

    it "raises an exception" do
      expect { subject }.
        to raise_error(Vagrant::Errors::BoxMetadataMalformed)
    end
  end

  context "with poorly formatted version" do
    let(:raw) {
      <<-RAW
      { "name": "foo",
        "versions": [
          {
            "version": "I AM NOT VALID"
          }
        ]
      }
      RAW
    }

    it "raises an exception" do
      expect { subject }.
        to raise_error(Vagrant::Errors::BoxMetadataMalformedVersion)
    end
  end

  describe "#version" do
    it "matches an exact version" do
      result = subject.version("1.0.0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
      expect(result.version).to eq("1.0.0")
    end

    it "matches a constraint with latest matching version" do
      result = subject.version(">= 1.0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
      expect(result.version).to eq("1.1.5")
    end

    it "matches complex constraints" do
      result = subject.version(">= 0.9, ~> 1.0.0")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
      expect(result.version).to eq("1.0.0")
    end

    it "matches the constraint that has the given provider" do
      result = subject.version(">= 0", provider: :vmware)
      expect(result).to_not be_nil
      expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
      expect(result.version).to eq("1.1.0")
    end
  end

  describe "#versions" do
    it "returns the versions it contained" do
      expect(subject.versions).to eq(
        ["1.0.0", "1.1.0", "1.1.5"])
    end
  end
end

describe Vagrant::BoxMetadata::Version do
  let(:raw) { {} }

  subject { described_class.new(raw) }

  before do
    raw["providers"] = [
      {
        "name" => "virtualbox",
      },
      {
        "name" => "vmware",
      }
    ]
  end

  describe "#version" do
    it "is the version in the raw data" do
      v = "1.0"
      raw["version"] = v
      expect(subject.version).to eq(v)
    end
  end

  describe "#provider" do
    it "returns nil if a provider isn't supported" do
      expect(subject.provider("foo")).to be_nil
    end

    it "returns the provider specified" do
      result = subject.provider("virtualbox")
      expect(result).to_not be_nil
      expect(result).to be_kind_of(Vagrant::BoxMetadata::Provider)
    end
  end

  describe "#providers" do
    it "returns the providers available" do
      expect(subject.providers.sort).to eq(
        [:virtualbox, :vmware])
    end
  end
end

describe Vagrant::BoxMetadata::Provider do
  let(:raw) { {} }

  subject { described_class.new(raw) }

  describe "#name" do
    it "is the name specified" do
      raw["name"] = "foo"
      expect(subject.name).to eq("foo")
    end
  end

  describe "#url" do
    it "is the URL specified" do
      raw["url"] = "bar"
      expect(subject.url).to eq("bar")
    end
  end

  describe "#checksum and #checksum_type" do
    it "is set properly" do
      raw["checksum"] = "foo"
      raw["checksum_type"] = "bar"

      expect(subject.checksum).to eq("foo")
      expect(subject.checksum_type).to eq("bar")
    end

    it "is nil if not set" do
      expect(subject.checksum).to be_nil
      expect(subject.checksum_type).to be_nil
    end
  end
end
