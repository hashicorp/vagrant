require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/package")

describe VagrantPlugins::Kernel_V2::PackageConfig do
  subject { described_class.new }

  describe "#name" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.name).to be_nil
    end
  end
end
