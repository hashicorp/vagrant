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

    it "allows provisioner settings to be overriden" do
      subject.provision("shell", path: "foo", inline: "foo", id: "s")
      subject.provision("shell", inline: "bar", id: "s")
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(1)
      expect(r[0].config.inline).to eql("bar")
      expect(r[0].config.path).to eql("foo")
    end

    it "marks as invalid if a bad name" do
      subject.provision("nope", inline: "foo")
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(1)
      expect(r[0]).to be_invalid
    end
  end
end
