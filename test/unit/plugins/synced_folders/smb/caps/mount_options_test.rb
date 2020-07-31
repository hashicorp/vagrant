require_relative "../../../../base"

require_relative "../../../../../../plugins/synced_folders/smb/cap/mount_options"

describe VagrantPlugins::SyncedFolderSMB::Cap::MountOptions do

  let(:caps) do
    VagrantPlugins::SyncedFolderSMB::Plugin
      .components
      .synced_folder_capabilities[:smb]
  end
  let(:cap){ caps.get(:mount_options) }

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:mount_owner){ "vagrant" }
  let(:mount_group){ "vagrant" }
  let(:mount_uid){ "1000" }
  let(:mount_gid){ "1000" }
  let(:mount_name){ "vagrant" }
  let(:mount_guest_path){ "/vagrant" }
  let(:folder_options) do
    {
      owner: mount_owner,
      group: mount_group,
      hostpath: "/host/directory/path"
    }
  end

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive_message_chain(:env, :host, :capability?).with(:smb_mount_options).and_return(false)
    ENV['VAGRANT_DISABLE_SMBMFSYMLINKS'] = "1"
  end

  describe ".mount_options" do
    it "generates the expected default mount command" do
      expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
      expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      out_opts, out_uid, out_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
      expect(out_opts).to eq("sec=ntlmssp,credentials=/etc/smb_creds_vagrant,uid=1000,gid=1000")
      expect(out_uid).to eq(mount_uid)
      expect(out_gid).to eq(mount_gid)
    end

    it "includes provided mount options" do
      expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
      expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      folder_options[:mount_options] =["ro"]
      out_opts, out_uid, out_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
      expect(out_opts).to eq("sec=ntlmssp,credentials=/etc/smb_creds_vagrant,uid=1000,gid=1000,ro")
      expect(out_uid).to eq(mount_uid)
      expect(out_gid).to eq(mount_gid)
    end

    context "with non-existent owner group" do
      it "raises an error" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("id -g #{mount_group}", anything).and_yield(:stdout, mount_gid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_raise(Vagrant::Errors::VirtualBoxMountFailed, {command: '', output: ''})
        expect do
          cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        end.to raise_error Vagrant::Errors::VirtualBoxMountFailed
      end
    end
  end
end
