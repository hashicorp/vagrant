# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::MountVirtualBoxSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
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
        hostpath: "/host/directory/path",
        plugin: folder_plugin
      }
    ]
  end
  let(:cap){ caps.get(:mount_virtualbox_shared_folder) }
  let(:folder_plugin) { double("folder_plugin") }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_virtualbox_shared_folder" do

    before do
      allow(comm).to receive(:sudo).with(any_args)
      allow(comm).to receive(:execute).with(any_args)
    end

    it "generates the expected default mount command" do
      expect(folder_plugin).to receive(:capability).with(:mount_options, mount_name, mount_guest_path, folder_options).
        and_return(["uid=#{mount_uid},gid=#{mount_gid}", mount_uid, mount_gid])
      expect(folder_plugin).to receive(:capability).with(:mount_type).and_return("vboxsf")
      expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)

      cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "automatically chown's the mounted directory on guest" do
      expect(folder_plugin).to receive(:capability).with(:mount_options, mount_name, mount_guest_path, folder_options).
        and_return(["uid=#{mount_uid},gid=#{mount_gid}", mount_uid, mount_gid])
      expect(folder_plugin).to receive(:capability).with(:mount_type).and_return("vboxsf")
      expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
      expect(comm).to receive(:sudo).with("chown #{mount_uid}:#{mount_gid} #{mount_guest_path}")

      cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    context "with upstart init" do

      it "emits mount event" do
        expect(comm).to receive(:sudo).with(/initctl emit/)
        expect(folder_plugin).to receive(:capability).with(:mount_type).and_return("vboxsf")
        expect(folder_plugin).to receive(:capability).with(:mount_options, mount_name, mount_guest_path, folder_options).
          and_return(["uid=#{mount_uid},gid=#{mount_gid}", mount_uid, mount_gid])

        cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end
    end

    context "with guest builtin vboxsf module" do
      let(:vbox_stderr){ <<-EOF
mount.vboxsf cannot be used with mainline vboxsf; instead use:

    mount -cit vboxsf NAME MOUNTPOINT
EOF
      }
      it "should perform guest mount using builtin module" do
        expect(folder_plugin).to receive(:capability).with(:mount_options, mount_name, mount_guest_path, folder_options).
          and_return(["uid=#{mount_uid},gid=#{mount_gid}", mount_uid, mount_gid])
        expect(folder_plugin).to receive(:capability).with(:mount_type).and_return("vboxsf")
        expect(comm).to receive(:sudo).with(/mount -t vboxsf/, any_args).and_yield(:stderr, vbox_stderr).and_return(1)
        expect(comm).to receive(:sudo).with(/mount -cit/, any_args)

        cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end
    end
  end

  describe ".unmount_virtualbox_shared_folder" do

    after { cap.unmount_virtualbox_shared_folder(machine, mount_guest_path, folder_options) }

    it "unmounts shared directory and deletes directory on guest" do
      expect(comm).to receive(:sudo).with("umount #{mount_guest_path}", anything).and_return(0)
      expect(comm).to receive(:sudo).with("rmdir #{mount_guest_path}", anything)
    end

    it "does not delete guest directory if unmount fails" do
      expect(comm).to receive(:sudo).with("umount #{mount_guest_path}", anything).and_return(1)
      expect(comm).not_to receive(:sudo).with("rmdir #{mount_guest_path}", anything)
    end
  end
end
