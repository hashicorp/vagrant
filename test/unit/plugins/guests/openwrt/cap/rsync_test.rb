# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::VagrantPlugins::Cap::Rsync" do
  let(:caps) do
    VagrantPlugins::GuestOpenWrt::Plugin
        .components
        .guest_capabilities[:openwrt]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:guest_directory) { "/guest/directory/path" }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".rsync_installed" do
    let(:cap) { caps.get(:rsync_installed) }

    describe "when rsync is in the path" do
      it "is true" do
        comm.stub_command("which rsync", stdout: '/usr/bin/rsync', exit_code: 0)
        expect(cap.rsync_installed(machine)).to be true
      end
    end

    describe "when rsync is not in the path" do
      it "is false" do
        comm.stub_command("which rsync", stdout: '', exit_code: 1)
        expect(cap.rsync_installed(machine)).to be false
      end
    end
  end

  describe ".rsync_install" do
    let(:cap) { caps.get(:rsync_install) }

    it "installs rsync" do
      cap.rsync_install(machine)

      expect(comm.received_commands[0]).to match(/opkg update/)
      expect(comm.received_commands[0]).to match(/opkg install rsync/)
    end
  end

  describe ".rsync_command" do
    let(:cap) { caps.get(:rsync_command) }

    it "provides the rsync command to use" do
      expect(cap.rsync_command(machine)).to eq("rsync -zz")
    end
  end

  describe ".rsync_pre" do
    let(:cap) { caps.get(:rsync_pre) }

    it "creates target directory on guest" do
      cap.rsync_pre(machine, :guestpath => guest_directory)
      expect(comm.received_commands[0]).to match(/mkdir -p '\/guest\/directory\/path'/)
    end
  end

  describe ".rsync_post" do
    let(:cap) { caps.get(:rsync_post) }

    it "is a no-op" do
      cap.rsync_post(machine, {})
      expect(comm).to_not receive(:execute)
    end
  end
end
