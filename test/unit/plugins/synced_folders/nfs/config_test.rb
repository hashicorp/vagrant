require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/synced_folders/nfs/config")

describe VagrantPlugins::SyncedFolderNFS::Config do
  subject { described_class.new }

  context "defaults" do
    before do
      subject.finalize!
    end

    its(:functional) { should be(true) }
    its(:map_gid) { should eq(:auto) }
    its(:map_uid) { should eq(:auto) }
  end
end
