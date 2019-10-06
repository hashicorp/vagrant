require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/bsd/cap/nfs"
require_relative "../../../../../../lib/vagrant/util"

describe VagrantPlugins::HostBSD::Cap::NFS do

  include_context "unit"

  describe ".nfs_check_folders_for_apfs" do
    it "should prefix host paths that are mounted in /System/Volumes/Data" do
      output_from_df = <<-EOH
Filesystem    512-blocks      Used Available Capacity iused      ifree %iused  Mounted on
/dev/disk1s1   976490568 392813584 555082648    42% 1177049 4881275791    0%   /System/Volumes/Data
EOH
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(
        Vagrant::Util::Subprocess::Result.new(0, output_from_df, "")
      )

      folders = {"/vagrant"=>{:hostpath=>"/Users/johndoe/vagrant",:bsd__nfs_options=>["rw"]}}
      described_class.nfs_check_folders_for_apfs(folders)
      expect(folders["/vagrant"][:hostpath]).to eq("/System/Volumes/Data/Users/johndoe/vagrant")
    end

    it "should not prefix host paths that are mounted in elsewhere" do
      output_from_df = <<-EOH
Filesystem    512-blocks      Used Available Capacity iused      ifree %iused  Mounted on
/dev/disk1s5   976490568  20634032 554201072     4%  481588 4881971252    0%   /
EOH
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(
        Vagrant::Util::Subprocess::Result.new(0, output_from_df, "")
      )

      folders = {"/vagrant"=>{:hostpath=>"/",:bsd__nfs_options=>["rw"]}}
      described_class.nfs_check_folders_for_apfs(folders)
      expect(folders["/vagrant"][:hostpath]).to eq("/")
    end

  end
end
