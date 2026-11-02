# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::PersistMountSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:options_gid){ '1234' }
  let(:options_uid){ '1234' }
  let(:cap){ caps.get(:persist_mount_shared_folder) }
  let(:folder_plugin){ double("folder_plugin") }
  let(:ssh_info) {{
    :username => "vagrant"
  }}
  let (:fstab_folders) {
    Vagrant::Plugin::V2::SyncedFolder::Collection[
      {
        "test1" => {guestpath: "/test1", hostpath: "/my/host/path", disabled: false, plugin: folder_plugin,
          __vagrantfile: true, owner: "vagrant", group: "vagrant", mount_options: ["uid=#{options_uid}", "gid=#{options_gid}"]},
        "vagrant" => {guestpath: "/vagrant", hostpath: "/my/host/vagrant", disabled: false, __vagrantfile: true,
          owner: "vagrant", group: "vagrant", mount_options: ["uid=#{options_uid}", "gid=#{options_gid}}"], plugin: folder_plugin}
      }
    ]
  }
  let (:folders) { {
    :folder_type => fstab_folders
  } }
  let(:expected_mount_options) { "uid=#{options_uid},gid=#{options_gid}" }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:ssh_info).and_return(ssh_info)
    allow(folder_plugin).to receive(:capability?).with(:mount_name).and_return(false)
    allow(folder_plugin).to receive(:capability?).with(:mount_type).and_return(true)
    allow(folder_plugin).to receive(:capability).with(:mount_options, any_args).
      and_return(["uid=#{options_uid},gid=#{options_gid}", options_uid, options_gid])
    allow(folder_plugin).to receive(:capability).with(:mount_type).and_return("vboxsf")
    allow(cap).to receive(:fstab_exists?).and_return(true)
  end

  after do
    comm.verify_expectations!
  end

  describe ".persist_mount_shared_folder" do

    let(:ui){ Vagrant::UI::Silent.new }

    before do
      allow(comm).to receive(:sudo).with(any_args)
      allow(machine).to receive(:ui).and_return(ui)
    end

    it "inserts folders into /etc/fstab" do
      expected_entry_vagrant = "vagrant /vagrant vboxsf #{expected_mount_options} 0 0"
      expected_entry_test = "test1 /test1 vboxsf #{expected_mount_options} 0 0"
      expect(cap).to receive(:remove_vagrant_managed_fstab)
      expect(comm).to receive(:sudo).with(/#{expected_entry_test}\n#{expected_entry_vagrant}/)

      cap.persist_mount_shared_folder(machine, folders)
    end

    it "does not insert an empty set of folders" do
      expect(cap).to receive(:remove_vagrant_managed_fstab)
      cap.persist_mount_shared_folder(machine, nil)
    end

    context "folders do not support mount_type capability" do
      before do
        allow(folder_plugin).to receive(:capability?).with(:mount_type).and_return(false)
      end

      it "does not inserts folders into /etc/fstab" do
        expect(cap).to receive(:remove_vagrant_managed_fstab)
        expect(comm).not_to receive(:sudo).with(/echo '' >> \/etc\/fstab/)
        cap.persist_mount_shared_folder(machine, folders)
      end
    end

    context "fstab does not exist" do
      before do
        allow(cap).to receive(:fstab_exists?).and_return(false)
        # Ensure /etc/fstab is not being modified
        expect(comm).not_to receive(:sudo).with(/sed -i .? \/etc\/fstab/)
      end

      it "creates /etc/fstab" do
        expect(cap).to receive(:remove_vagrant_managed_fstab)
        expect(comm).to receive(:sudo).with(/>> \/etc\/fstab/)
        cap.persist_mount_shared_folder(machine, [])
      end

      it "does not remove contents of /etc/fstab" do
        expect(cap).to receive(:remove_vagrant_managed_fstab)
        expect(comm).not_to receive(:sudo).with(/echo '' >> \/etc\/fstab/)
        cap.persist_mount_shared_folder(machine, nil)
      end
    end

    context "smb folder" do
      let (:fstab_folders) {
        Vagrant::Plugin::V2::SyncedFolder::Collection[
          {
            "test1" => {guestpath: "/test1", hostpath: "/my/host/path", disabled: false, plugin: folder_plugin,
              __vagrantfile: true, owner: "vagrant", group: "vagrant", smb_host: "192.168.42.42", smb_id: "vtg-id1" },
            "vagrant" => {guestpath: "/vagrant", hostpath: "/my/host/vagrant", disabled: false, plugin: folder_plugin,
               __vagrantfile: true, owner: "vagrant", group: "vagrant", smb_host: "192.168.42.42", smb_id: "vtg-id2"}
          }
        ]
      }
      let (:folders) { {
        :smb => fstab_folders
      } }

      context "folder with mount_name cap" do
        before do
          allow(folder_plugin).to receive(:capability).with(:mount_type).and_return("cifs")
          allow(folder_plugin).to receive(:capability?).with(:mount_name).and_return(true)
          allow(folder_plugin).to receive(:capability).with(:mount_name, instance_of(String), any_args).and_return("//192.168.42.42/dummyname")
        end

        it "inserts folders into /etc/fstab" do
          expected_entry_vagrant = "//192.168.42.42/dummyname /vagrant cifs #{expected_mount_options} 0 0"
          expected_entry_test = "//192.168.42.42/dummyname /test1 cifs #{expected_mount_options} 0 0"
          expect(cap).to receive(:remove_vagrant_managed_fstab)
          expect(comm).to receive(:sudo).with(/#{expected_entry_test}\n#{expected_entry_vagrant}/)

          cap.persist_mount_shared_folder(machine, folders)
        end
      end
    end
  end
end
