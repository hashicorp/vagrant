# Copyright (c) 2015 VMware, Inc. All Rights Reserved.

require_relative "../../../../base"

describe "VagrantPlugins::GuestPhoton::Cap:ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestPhoton::Plugin
      .components
      .guest_capabilities[:photon]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    comm.stub_command("ifconfig | grep 'eth' | cut -f1 -d' '",
      stdout: "eth1\neth2")
  end

  after do
    comm.verify_expectations!
  end

  describe ".configure_networks" do
    let(:cap) { caps.get(:configure_networks) }

    let(:network_1) do
      {
        interface: 0,
        type: "dhcp",
      }
    end

    let(:network_2) do
      {
        interface: 1,
        type: "static",
        ip: "33.33.33.10",
        netmask: "255.255.0.0",
        gateway: "33.33.0.1",
      }
    end

    it "creates and starts the networks" do
      cap.configure_networks(machine, [network_1, network_2])
      expect(comm.received_commands[1]).to match(/ifconfig eth1/)
      expect(comm.received_commands[1]).to match(/ifconfig eth2 33.33.33.10 netmask 255.255.0.0/)
    end
  end
end
