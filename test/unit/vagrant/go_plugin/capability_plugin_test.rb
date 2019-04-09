require_relative "../../base"

describe Vagrant::GoPlugin::CapabilityPlugin do
  let(:client) { double("client") }

  describe Vagrant::GoPlugin::CapabilityPlugin::Capability do
    it "should be a GRPCPlugin" do
      expect(described_class.ancestors).to include(Vagrant::GoPlugin::GRPCPlugin)
    end
  end

  describe ".generate_guest_capabilities" do
    let(:caps) {
      [{platform: "dummy", name: "stub_cap"},
        {platform: "dummy", name: "other_cap"}]}
    let(:cap_response) {
      Vagrant::Proto::SystemCapabilityList.new(
        capabilities: caps.map { |i|
          Vagrant::Proto::SystemCapability.new(i)})}
    let(:plugin_klass) { double("plugin_klass") }
    let(:plugin_type) { :testing }


    before do
      allow(client).to receive(:guest_capabilities).
        and_return(cap_response)
      allow(plugin_klass).to receive(:guest_capability)
    end

    it "should generate two new capability classes" do
      expect(Class).to receive(:new).twice.
        with(Vagrant::GoPlugin::CapabilityPlugin::Capability).
        and_call_original
      described_class.generate_guest_capabilities(client, plugin_klass, plugin_type)
    end

    it "should create capability name methods" do
      c1 = Class.new(Vagrant::GoPlugin::CapabilityPlugin::Capability)
      c2 = Class.new(Vagrant::GoPlugin::CapabilityPlugin::Capability)
      expect(Class).to receive(:new).and_return(c1)
      expect(Class).to receive(:new).and_return(c2)
      described_class.generate_guest_capabilities(client, plugin_klass, plugin_type)
      expect(c1).to respond_to(:stub_cap)
      expect(c2).to respond_to(:other_cap)
    end

    it "should register guest capability" do
      expect(plugin_klass).to receive(:guest_capability).with(:dummy, :stub_cap)
      expect(plugin_klass).to receive(:guest_capability).with(:dummy, :other_cap)
      described_class.generate_guest_capabilities(client, plugin_klass, plugin_type)
    end
  end

  describe ".generate_host_capabilities" do
    let(:caps) {
      [{platform: "dummy", name: "stub_cap"},
        {platform: "dummy", name: "other_cap"}]}
    let(:cap_response) {
      Vagrant::Proto::SystemCapabilityList.new(
        capabilities: caps.map { |i|
          Vagrant::Proto::SystemCapability.new(i)})}
    let(:plugin_klass) { double("plugin_klass") }
    let(:plugin_type) { :testing }


    before do
      allow(client).to receive(:host_capabilities).
        and_return(cap_response)
      allow(plugin_klass).to receive(:host_capability)
    end

    it "should generate two new capability classes" do
      expect(Class).to receive(:new).twice.
        with(Vagrant::GoPlugin::CapabilityPlugin::Capability).
        and_call_original
      described_class.generate_host_capabilities(client, plugin_klass, plugin_type)
    end

    it "should create capability name methods" do
      c1 = Class.new(Vagrant::GoPlugin::CapabilityPlugin::Capability)
      c2 = Class.new(Vagrant::GoPlugin::CapabilityPlugin::Capability)
      expect(Class).to receive(:new).and_return(c1)
      expect(Class).to receive(:new).and_return(c2)
      described_class.generate_host_capabilities(client, plugin_klass, plugin_type)
      expect(c1).to respond_to(:stub_cap)
      expect(c2).to respond_to(:other_cap)
    end

    it "should register host capability" do
      expect(plugin_klass).to receive(:host_capability).with(:dummy, :stub_cap)
      expect(plugin_klass).to receive(:host_capability).with(:dummy, :other_cap)
      described_class.generate_host_capabilities(client, plugin_klass, plugin_type)
    end
  end

  describe ".generate_provider_capabilities" do
    let(:caps) {
      [{provider: "dummy", name: "stub_cap"},
        {provider: "dummy", name: "other_cap"}]}
    let(:cap_response) {
      Vagrant::Proto::ProviderCapabilityList.new(
        capabilities: caps.map { |i|
          Vagrant::Proto::ProviderCapability.new(i)})}
    let(:plugin_klass) { double("plugin_klass") }
    let(:plugin_type) { :testing }


    before do
      allow(client).to receive(:provider_capabilities).
        and_return(cap_response)
      allow(plugin_klass).to receive(:provider_capability)
    end

    it "should generate two new capability classes" do
      expect(Class).to receive(:new).twice.
        with(Vagrant::GoPlugin::CapabilityPlugin::Capability).
        and_call_original
      described_class.generate_provider_capabilities(client, plugin_klass, plugin_type)
    end

    it "should create capability name methods" do
      c1 = Class.new(Vagrant::GoPlugin::CapabilityPlugin::Capability)
      c2 = Class.new(Vagrant::GoPlugin::CapabilityPlugin::Capability)
      expect(Class).to receive(:new).and_return(c1)
      expect(Class).to receive(:new).and_return(c2)
      described_class.generate_provider_capabilities(client, plugin_klass, plugin_type)
      expect(c1).to respond_to(:stub_cap)
      expect(c2).to respond_to(:other_cap)
    end

    it "should register provider capability" do
      expect(plugin_klass).to receive(:provider_capability).with(:dummy, :stub_cap)
      expect(plugin_klass).to receive(:provider_capability).with(:dummy, :other_cap)
      described_class.generate_provider_capabilities(client, plugin_klass, plugin_type)
    end
  end
end
