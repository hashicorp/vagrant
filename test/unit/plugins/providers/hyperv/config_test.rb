require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/config")

describe VagrantPlugins::HyperV::Config do
  describe "#ip_address_timeout" do
    it "can be set" do
      subject.ip_address_timeout = 180
      subject.finalize!
      expect(subject.ip_address_timeout).to eq(180)
    end

    it "defaults to a number" do
      subject.finalize!
      expect(subject.ip_address_timeout).to eq(120)
    end
  end
end
