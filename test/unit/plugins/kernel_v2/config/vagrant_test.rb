require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vagrant")

describe VagrantPlugins::Kernel_V2::VagrantConfig do
  subject { described_class.new }

  let(:machine){ double("machine") }

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

  describe "#sensitive" do
    after{ Vagrant::Util::CredentialScrubber.reset! }

    it "accepts string value" do
      subject.sensitive = "test"
      subject.finalize!
      expect(subject.sensitive).to eq("test")
    end

    it "accepts array of values" do
      subject.sensitive = ["test1", "test2"]
      subject.finalize!
      expect(subject.sensitive).to eq(["test1", "test2"])
    end

    it "does not accept non-string values" do
      subject.sensitive = 1
      subject.finalize!
      result = subject.validate(machine)
      expect(result).to be_a(Hash)
      expect(result.values).not_to be_empty
    end

    it "registers single sensitive value to be scrubbed" do
      subject.sensitive = "test"
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("test")
      subject.finalize!
    end

    it "registers multiple sensitive values to be scrubbed" do
      subject.sensitive = ["test1", "test2"]
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("test1")
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("test2")
      subject.finalize!
    end
  end
end
