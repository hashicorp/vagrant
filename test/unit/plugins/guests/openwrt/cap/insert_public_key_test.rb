# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestOpenWrt::Cap::InsertPublicKey" do
  let(:caps) do
    VagrantPlugins::GuestOpenWrt::Plugin
        .components
        .guest_capabilities[:openwrt]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".insert_public_key" do
    let(:cap) { caps.get(:insert_public_key) }

    it "inserts the public key" do
      cap.insert_public_key(machine, "ssh-rsa ...")

      expect(comm.received_commands[0]).to match(/printf 'ssh-rsa ...\\n' >> \/etc\/dropbear\/authorized_keys/)
    end
  end
end
