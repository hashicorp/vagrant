require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vagrant")

describe VagrantPlugins::Kernel_V2::VagrantConfig do
  subject { described_class.new }

  describe "#host" do
    it "defaults to :detect" do
      subject.finalize!
      expect(subject.host).to eq(:detect)
    end

    it "symbolizes" do
      subject.host = "foo"
      subject.finalize!
      expect(subject.host).to eq(:foo)
    end
  end
end
