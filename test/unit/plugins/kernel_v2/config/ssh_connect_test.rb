require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/ssh_connect")

describe VagrantPlugins::Kernel_V2::SSHConnectConfig do
  subject { described_class.new }

  describe "#verify_host_key" do
    it "defaults to :never" do
      subject.finalize!
      expect(subject.verify_host_key).to eq(:never)
    end

    it "should modify true value to :accepts_new_or_local_tunnel" do
      subject.verify_host_key = true
      subject.finalize!
      expect(subject.verify_host_key).to eq(:accepts_new_or_local_tunnel)
    end

    it "should modify :very value to :accept_new" do
      subject.verify_host_key = :very
      subject.finalize!
      expect(subject.verify_host_key).to eq(:accept_new)
    end

    it "should modify :secure to :always" do
      subject.verify_host_key = :secure
      subject.finalize!
      expect(subject.verify_host_key).to eq(:always)
    end
  end
end
