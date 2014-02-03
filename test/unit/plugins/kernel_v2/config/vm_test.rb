require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe VagrantPlugins::Kernel_V2::VMConfig do
  subject { described_class.new }

  describe "#provision" do
    it "stores the provisioners" do
      subject.provision("shell", inline: "foo")
      subject.provision("shell", inline: "bar")
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(2)
      expect(r[0].config.inline).to eql("foo")
      expect(r[1].config.inline).to eql("bar")
    end
  end
end
