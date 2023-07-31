# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/synced_folders/smb/cap/mount_options"

describe VagrantPlugins::SyncedFolderSMB::Cap::MountOptions do

  let(:caps) do
    VagrantPlugins::SyncedFolderSMB::Plugin
      .components
      .synced_folder_capabilities[:smb]
  end
  let(:cap){ caps.get(:mount_options) }

  let(:dummy_smb_host) { "my.smb.host" }
  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:env)    { double("env") }
  let(:guest) { double("guest") }
  let(:host)    { double("host") }
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
    allow(guest).to receive(:capability).with(:choose_addressable_ip_addr, any_args).and_return(dummy_smb_host)
    allow(host).to receive(:capability).with(:configured_ip_addresses)
    allow(env).to receive(:host).and_return(host)
    allow(machine).to receive(:env).and_return(env)
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:guest).and_return(guest)
    allow(machine).to receive_message_chain(:env, :host, :capability?).with(:smb_mount_options).and_return(false)
    allow(ENV).to receive(:[]).with("VAGRANT_DISABLE_SMBMFSYMLINKS").and_return(true)
    allow(ENV).to receive(:[]).with("GEM_SKIP").and_return(false)
  end

  describe ".mount_name" do
    it "generates the mount name when smb_host and smb_id are set" do
      folder_options[:smb_host] = "smb_host"
      folder_options[:smb_id] = "smbid"
      mn = cap.mount_name(machine, "", folder_options)
      expect(mn).to eq("//smb_host/smbid")
    end

    it "generates the mount name when smb_host is not set" do
      folder_options[:smb_id] = "smbid"
      mn = cap.mount_name(machine, "", folder_options)
      expect(mn).to eq("//#{dummy_smb_host}/smbid")
    end
  end

  describe ".mount_options" do
    context "with valid existent owner group" do

      before do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      end

      it "generates the expected default mount command" do
        out_opts, out_uid, out_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        expect(out_opts).to eq("sec=ntlmssp,credentials=/etc/smb_creds_vagrant,uid=1000,gid=1000,_netdev,nofail")
        expect(out_uid).to eq(mount_uid)
        expect(out_gid).to eq(mount_gid)
      end
      
      it "includes provided mount options" do
        folder_options[:mount_options] =["ro"]
        out_opts, out_uid, out_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        expect(out_opts).to eq("sec=ntlmssp,credentials=/etc/smb_creds_vagrant,uid=1000,gid=1000,_netdev,ro,nofail")
        expect(out_uid).to eq(mount_uid)
        expect(out_gid).to eq(mount_gid)
      end

      it "overwrites default mount options" do
        folder_options[:mount_options] =["ro", "sec=custom"]
        out_opts, out_uid, out_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        expect(out_opts).to eq("sec=custom,credentials=/etc/smb_creds_vagrant,uid=1000,gid=1000,_netdev,ro,nofail")
        expect(out_uid).to eq(mount_uid)
        expect(out_gid).to eq(mount_gid)
      end

      it "does not add mfsymlinks option if env var VAGRANT_DISABLE_SMBMFSYMLINKS exists" do
        expect(ENV).to receive(:[]).with("VAGRANT_DISABLE_SMBMFSYMLINKS").and_return(false)
        out_opts, out_uid, out_gid = cap.mount_options(machine, mount_name, mount_guest_path, folder_options)
        expect(out_opts).to eq("sec=ntlmssp,credentials=/etc/smb_creds_vagrant,uid=1000,gid=1000,mfsymlinks,_netdev,nofail")
        expect(out_uid).to eq(mount_uid)
        expect(out_gid).to eq(mount_gid)
      end
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
