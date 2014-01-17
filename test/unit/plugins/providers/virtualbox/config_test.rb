require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/config")

describe VagrantPlugins::ProviderVirtualBox::Config do
  context "defaults" do
    before { subject.finalize! }

    it "should have one NAT adapter" do
      expect(subject.network_adapters).to eql({
        1 => [:nat, {}],
      })
    end
  end

  describe "#network_adapter" do
    it "configures additional adapters" do
      subject.network_adapter(2, :bridged, auto_config: true)
      expect(subject.network_adapters[2]).to eql(
        [:bridged, auto_config: true])
    end
  end
end
