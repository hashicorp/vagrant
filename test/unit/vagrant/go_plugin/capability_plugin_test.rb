require_relative "../../base"

describe Vagrant::GoPlugin::CapabilityPlugin do
  describe Vagrant::GoPlugin::CapabilityPlugin::Capability do
    it "should be a TypedGoPlugin" do
      expect(described_class.ancestors).to include(Vagrant::GoPlugin::TypedGoPlugin)
    end
  end

  describe ".interface" do
    it "should create an interface instance" do
      expect(described_class.interface).to be_a(Vagrant::GoPlugin::CapabilityHost::Interface)
    end

    it "should cache generated interface" do
      expect(described_class.interface).to be(described_class.interface)
    end
  end
end
