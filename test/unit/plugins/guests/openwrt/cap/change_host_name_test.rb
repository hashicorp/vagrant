# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestOpenWrt::Cap::ChangeHostName" do
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

  describe ".change_host_name" do
    let(:cap) { caps.get(:change_host_name) }

    it "changes the hostname if appropriate" do
      cap.change_host_name(machine, "testhost")

      expect(comm.received_commands[0]).to match(/uci get system\.@system\[0\].hostname | grep '^testhost$'/)
      expect(comm.received_commands[1]).to match(/uci set system.@system\[0\].hostname='testhost'/)
      expect(comm.received_commands[1]).to match(/uci commit system/)
      expect(comm.received_commands[1]).to match(/\/etc\/init.d\/system reload/)
    end
  end
end
