require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/config")

describe VagrantPlugins::ProviderVirtualBox::Config do
  context "defaults" do
    subject { VagrantPlugins::ProviderVirtualBox::Config.new }

    before { subject.finalize! }

    it { expect(subject.check_guest_additions).to be_true }
    it { expect(subject.gui).to be_false }
    it { expect(subject.name).to be_nil }
    it { expect(subject.functional_vboxsf).to be_true }

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
