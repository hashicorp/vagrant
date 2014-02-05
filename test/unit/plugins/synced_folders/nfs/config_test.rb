require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/synced_folders/nfs/config")

describe VagrantPlugins::SyncedFolderNFS::Config do
  subject { described_class.new }

  describe "#map_gid" do
    it "defaults to :auto" do
      subject.finalize!
      expect(subject.map_gid).to eq(:auto)
    end
  end

  describe "#map_uid" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.map_uid).to eq(:auto)
    end
  end
end
