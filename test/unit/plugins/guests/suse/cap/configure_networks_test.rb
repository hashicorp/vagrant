# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:guest) { double("guest") }
  let(:machine) { double("machine", guest: guest) }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
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

    context "with wicked network configuration path" do
      before do
        allow(guest).to receive(:capability).with(:network_scripts_dir)
          .and_return("/etc/sysconfig/network")
        allow(guest).to receive(:capability).with(:network_interfaces)
          .and_return(["eth1", "eth2"])
      end

      it "creates and starts the networks" do
        cap.configure_networks(machine, [network_1, network_2])
        expect(comm.received_commands[0]).to match(/\/sbin\/ifdown 'eth1'/)
        expect(comm.received_commands[0]).to match(/\/sbin\/ifup 'eth1'/)
        expect(comm.received_commands[0]).to match(/\/sbin\/ifdown 'eth2'/)
        expect(comm.received_commands[0]).to match(/\/sbin\/ifup 'eth2'/)
      end
    end

    context "with system-connections network configuration path" do
      before do
        allow(guest).to receive(:capability).with(:network_scripts_dir)
          .and_return("/etc/NetworkManager/system-connections")
      end

      it "should configure with network manager" do
        expect(cap).to receive(:configure_network_manager).with(machine, [network_1, network_2])
        cap.configure_networks(machine, [network_1, network_2])
      end
    end
  end
end
