# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestBSD::Cap::MountVirtualBoxSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestBSD::Plugin
      .components
      .guest_capabilities[:bsd]
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
    {
      owner: mount_owner,
      group: mount_group,
      hostpath: "/host/directory/path"
    }
  end
  let(:cap){ caps.get(:mount_virtualbox_shared_folder) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_virtualbox_shared_folder" do
    it "raises an error as unsupported" do
      expect {cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options) }.
        to raise_error(Vagrant::Errors::VirtualBoxMountNotSupportedBSD)
    end
  end
end
