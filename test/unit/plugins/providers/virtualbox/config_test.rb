require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/config")

describe VagrantPlugins::ProviderVirtualBox::Config do
  context "defaults" do
    before { subject.finalize! }

    describe '#check_guest_additions' do
      subject { super().check_guest_additions }
      it { should be_true }
    end

    describe '#gui' do
      subject { super().gui }
      it { should be_false }
    end

    describe '#name' do
      subject { super().name }
      it { should be_nil }
    end

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
