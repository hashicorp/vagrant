# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../../base", __FILE__)

require "vagrant/box_metadata"

describe Vagrant::BoxMetadata do
  include_context "unit"

  let(:raw) do
    {
      name: "foo",
      description: "bar",
      versions: [
        {
          version: "1.0.0",
          providers: [
            { name: "virtualbox" },
            { name: "vmware" }
          ],
        },
        {
          version: "1.1.5",
          providers: [
            { name: "virtualbox" }
          ]
        },
        {
          version: "1.1.0",
          providers: [
            { name: "virtualbox" },
            { name: "vmware", architecture: "test-arch" }
          ]
        }
      ]
    }.to_json
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
      {name: "foo"}.to_json + ","
    }

    it "raises an exception" do
      expect { subject }.
        to raise_error(Vagrant::Errors::BoxMetadataMalformed)
    end
  end

  context "with poorly formatted version" do
    let(:raw) {
      {
        name: "foo",
        versions: [
          {
            version: "I AM NOT VALID"
          }
        ]
      }.to_json
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

    it "filters versions by matching provider" do
      expect(subject.versions(provider: :vmware)).to eq(
        ["1.0.0", "1.1.0"])
    end

    it "filters versions by architecture" do
      expect(subject.versions(architecture: "test-arch")).to eq(["1.1.0"])
    end

    it "filters versions by provider and architecture" do
      expect(subject.versions(architecture: "test-arch", provider: "virtualbox")).to eq([])
      expect(subject.versions(architecture: "test-arch", provider: "vmware")).to eq(["1.1.0"])
    end

    it "filters versions by multiple providers" do
      expect(subject.versions(provider: ["vmware", "my-virt"])).to eq(["1.0.0", "1.1.0"])
    end
  end
  
  describe "#compatible_version_update?" do 
    let(:raw) do
      {
        name: "foo",
        description: "bar",
        versions: [
          {
            version: "1.0.0",
            providers: [
              { name: "virtualbox" },
              { name: "vmware" }
            ],
          },
          {
            version: "1.1.5",
            providers: [
              { name: "virtualbox" }
            ]
          },
          {
            version: "1.1.0",
            providers: [
              { name: "virtualbox" },
              { name: "vmware" }
            ]
          }
        ]
      }.to_json
    end

    it "is compatible if current version is older than new version" do
      expect(subject.compatible_version_update?("1.0.0", "1.1.0", provider: "virtualbox")).to be true
      expect(subject.compatible_version_update?("1.1.5", "1.1.0", provider: "virtualbox")).to be false
    end

    it "is compatible if architecture is set and isn't defined in metadata" do
      expect(subject.compatible_version_update?("1.0.0", "1.1.0", provider: "virtualbox", architecture: :auto)).to be true
    end
  end

  context "with architecture" do
    let(:raw) do
      {
        name: "foo",
        description: "bar",
        versions: [
          {
            version: "1.0.0",
            providers: [
              {
                name: "virtualbox",
                default_architecture: true,
                architecture: "amd64"
              },
              {
                name: "virtualbox",
                default_architecture: false,
                architecture: "arm64"
              },
              {
                name: "vmware",
                default_architecture: true,
                architecture: "arm64"
              },
              {
                name: "vmware",
                default_architecture: false,
                architecture: "amd64"
              }
            ],
          },
          {
            version: "1.1.5",
            providers: [
              {
                name: "virtualbox",
                architecture: "amd64",
                default_architecture: true,
              }
            ]
          },
          {
            version: "1.1.6",
            providers: [
              {
                name: "virtualbox",
                architecture: "arm64",
                default_architecture: true,
              },
            ]
          },
          {
            version: "1.1.0",
            providers: [
              {
                name: "virtualbox",
                architecture: "amd64",
                default_architecture: true,
              },
              {
                name: "vmware",
                architecture: "amd64",
                default_architecture: true,
              }
            ]
          },
          {
            version: "2.0.0",
            providers: [
              {
                name: "vmware",
                architecture: "arm64",
                default_architecture: true,
              }
            ]
          }
        ]
      }.to_json
    end

    subject { described_class.new(raw) }

    before { allow(Vagrant::Util::Platform).to receive(:architecture).and_return("amd64") }

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

      context "with provider filter" do
        it "matches the constraint that has the given provider" do
          result = subject.version(">= 0", provider: :vmware)
          expect(result).to_not be_nil
          expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
          expect(result.version).to eq("1.1.0")
        end

        it "matches the exact version that has the given provider" do
          result = subject.version("1.0.0", provider: :virtualbox)
          expect(result).to_not be_nil
          expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
          expect(result.version).to eq("1.0.0")
        end

        it "does not match exact version that has given provider but not host architecture" do
          result = subject.version("1.1.6", provider: :virtualbox)
          expect(result).to be_nil
        end

        context "with architecture filter" do
          it "matches the exact version that has provider with host architecture when using :auto" do
            result = subject.version("1.0.0", provider: :virtualbox, architecture: :auto)
            expect(result).to_not be_nil
            expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
            expect(result.version).to eq("1.0.0")
          end

          it "matches the exact version that has provider with defined host architecture" do
            result = subject.version("1.0.0", provider: :virtualbox, architecture: "arm64")
            expect(result).to_not be_nil
            expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
            expect(result.version).to eq("1.0.0")
          end

          it "does not match the exact version that has provider with defined host architecture" do
            result = subject.version("1.0.0", provider: :virtualbox, architecture: "ppc64")
            expect(result).to be_nil
          end
        end
      end

      context "with architecture filter" do
        it "matches a constraint that has the detected host architecture" do
          result = subject.version("> 0", architecture: :auto)
          expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
          expect(result.version).to eq("1.1.5")
        end

        it "matches a constraint that has the provided architecture" do
          result = subject.version("> 0", architecture: "arm64")
          expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
          expect(result.version).to eq("2.0.0")
        end

        it "matches exact version that has the provided architecture" do
          result = subject.version("1.0.0", architecture: "arm64")
          expect(result).to be_kind_of(Vagrant::BoxMetadata::Version)
          expect(result.version).to eq("1.0.0")
        end

        it "does not match exact version that does not have provided architecture" do
          result = subject.version("2.0.0", architecture: "amd64")
          expect(result).to be_nil
        end
      end
    end

    describe "#versions" do
      it "returns the versions it contained" do
        expect(subject.versions).
          to eq(["1.0.0", "1.1.0", "1.1.5", "1.1.6", "2.0.0"])
      end

      context "with provider filter" do
        it "filters versions" do
          expect(subject.versions(provider: :vmware)).
            to eq(["1.0.0", "1.1.0", "2.0.0"])
        end
      end

      context "with architecture filter" do
        it "filters versions" do
          expect(subject.versions(architecture: "arm64")).
            to eq(["1.0.0", "1.1.6", "2.0.0"])
        end

        it "returns none when no matching architecture available" do
          expect(subject.versions(architecture: "other")).
            to be_empty
        end

        it "filters based on host architecture when :auto used" do
          expect(subject.versions(architecture: :auto)).
            to eq(subject.versions(architecture: "amd64"))
        end
      end
    end

    describe "#compatible_version_update?" do
      let(:raw) do
        {
          name: "foo",
          description: "bar",
          versions: [
            {
              version: "1.0.0",
              providers: [
                {
                  name: "vmware",
                  default_architecture: true,
                  architecture: "arm64"
                },
                {
                  name: "docker",
                  default_architecture: true,
                  architecture: "unknown"
                },
                {
                  name: "virtualbox",
                  default_architecture: true,
                  architecture: "unknown"
                },
                {
                  name: "other",
                  default_architecture: true,
                  architecture: "amd64"
                }
              ]
            },
            {
              version: "2.0.0",
              providers: [
                {
                  name: "vmware",
                  architecture: "arm64",
                  default_architecture: true,
                },
                {
                  name: "docker",
                  default_architecture: true,
                  architecture: "unknown"
                },
                {
                  name: "virtualbox",
                  default_architecture: true,
                  architecture: "amd64"
                },
                {
                  name: "other",
                  default_architecture: true,
                  architecture: "unknown"
                },
                {
                  name: "missing",
                  default_architecture: true,
                  architecture: "unknown"
                }
              ]
            }
          ]
        }.to_json
      end

      it "is compatible if architectures match" do
        expect(subject.compatible_version_update?("1.0.0", "2.0.0", provider: "vmware", architecture: "arm64")).to be true
      end

      it "is compatible if current arch is unknown, but newer arch matches system" do
        expect(subject.compatible_version_update?("1.0.0", "2.0.0", provider: "virtualbox", architecture: :auto)).to be true
      end

      it "is compatible if current architecture is unknown" do
        expect(subject.compatible_version_update?("1.0.0", "2.0.0", provider: "docker", architecture: :auto)).to be true
      end

      it "is compatible if current_version is not available from metadata" do
        expect(subject.compatible_version_update?("1.0.0", "2.0.0", provider: "missing", architecture: :auto)).to be true
      end

      it "is not compatible if current architecture is defined, but newer architecture is unknown" do
        expect(subject.compatible_version_update?("1.0.0", "2.0.0", provider: "other", architecture: :auto)).to be false
      end
      it "is compatible if current architecture is defined, but newer architecture is unknown, and architecture is set to nil" do
        expect(subject.compatible_version_update?("1.0.0", "2.0.0", provider: "other", architecture: nil)).to be true
      end
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

  describe "architecture" do
    it "is set properly" do
      raw["architecture"] = "test-arch"

      expect(subject.architecture).to eq("test-arch")
    end

    it "is nil if not set" do
      expect(subject.architecture).to be_nil
    end
  end

  describe "#architecture_support?" do
    it "is false if architecture is not supported" do
      expect(subject.architecture_support?).to be(false)
    end

    it "is true if architecture is supported" do
      raw["default_architecture"] = false

      expect(subject.architecture_support?).to be(true)
    end
  end
end
