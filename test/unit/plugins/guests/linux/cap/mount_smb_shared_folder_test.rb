# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::MountSMBSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine", env: env, config: config) }
  let(:env) { double("env", host: host, ui: Vagrant::UI::Silent.new, data_dir: double("data_dir")) }
  let(:host) { double("host") }
  let(:guest) { double("guest") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config) { double("config", vm: vm) }
  let(:vm) { double("vm" ) }
  let(:mount_owner){ "vagrant" }
  let(:mount_group){ "vagrant" }
  let(:mount_uid){ "1000" }
  let(:mount_gid){ "1000" }
  let(:mount_name){ "vagrant" }
  let(:mount_guest_path){ "/vagrant" }
  let(:folder_options) do
    Vagrant::Plugin::V2::SyncedFolder::Collection[
      {
        owner: mount_owner,
        group: mount_group,
        smb_host: "localhost",
        smb_username: "user",
        smb_password: "pass",
        plugin: folder_plugin
      }
    ]
  end
  let(:folder_plugin) { double("folder_plugin") }
  let(:cap){ caps.get(:mount_smb_shared_folder) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(host).to receive(:capability?).and_return(false)
    allow(vm).to receive(:allow_fstab_modification).and_return(true)

    allow(folder_plugin).to receive(:capability).with(:mount_options, mount_name, mount_guest_path, folder_options).
    and_return(["uid=#{mount_uid},gid=#{mount_gid},sec=ntlmssp,credentials=/etc/smb_creds_id", mount_uid, mount_gid])
    allow(folder_plugin).to receive(:capability).with(:mount_type).and_return("cifs")
    allow(folder_plugin).to receive(:capability).with(:mount_name, mount_name, folder_options).and_return("//localhost/#{mount_name}")
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_smb_shared_folder" do
    before do
      allow(comm).to receive(:sudo).with(any_args).and_return(0)
      allow(comm).to receive(:execute).with(any_args)
      allow(machine).to receive(:guest).and_return(guest)
      allow(guest).to receive(:capability).with(:shell_expand_guest_path, mount_guest_path).and_return(mount_guest_path)
      allow(ENV).to receive(:[]).with("VAGRANT_DISABLE_SMBMFSYMLINKS").and_return(false)
      allow(ENV).to receive(:[]).with("GEM_SKIP").and_return(false)
      allow(cap).to receive(:display_mfsymlinks_warning)
    end

    it "generates the expected default mount command" do
      expect(comm).to receive(:sudo).with(/mount -t cifs/, anything).and_return(0)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "creates directory on guest machine" do
      expect(comm).to receive(:sudo).with("mkdir -p #{mount_guest_path}")
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "writes username into guest credentials file" do
      expect(comm).to receive(:sudo).with(/smb_creds.*username=#{folder_options[:smb_username]}/m)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "writes password into guest credentials file" do
      expect(comm).to receive(:sudo).with(/smb_creds.*password=#{folder_options[:smb_password]}/m)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "removes the credentials file before completion" do
      allow(vm).to receive(:allow_fstab_modification).and_return(false)
      expect(comm).to receive(:sudo).with(/rm.+smb_creds_.+/)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "sends upstart notification after mount" do
      expect(comm).to receive(:sudo).with(/emit/)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end
  end

  describe ".display_mfsymlinks_warning" do
    let(:gate_file){ double("gate") }

    before do
      allow(env.data_dir).to receive(:join).and_return(gate_file)
      allow(gate_file).to receive(:exist?).and_return(false)
      allow(gate_file).to receive(:to_path).and_return("PATH")
      allow(FileUtils).to receive(:touch)
    end

    it "should output warning message" do
      expect(env.ui).to receive(:warn).with(/VAGRANT_DISABLE_SMBMFSYMLINKS=1/)
      cap.display_mfsymlinks_warning(env)
    end

    it "should not output warning message if gate file exists" do
      allow(gate_file).to receive(:exist?).and_return(true)

      expect(env.ui).not_to receive(:warn)
      cap.display_mfsymlinks_warning(env)
    end
  end
end
