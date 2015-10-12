require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/ssh")

describe VagrantPlugins::Kernel_V2::SSHConfig do
  subject { described_class.new }

  describe "#default" do
    it "defaults to vagrant username" do
      subject.finalize!
      expect(subject.default.username).to eq("vagrant")
    end
  end

  describe "#sudo_command" do
    it "defaults properly" do
      subject.finalize!
      expect(subject.sudo_command).to eq("sudo -E -H %c")
    end
  end
end
