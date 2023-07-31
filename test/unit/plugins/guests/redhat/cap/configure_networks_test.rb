# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
  end

  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config) { double("config", vm: vm) }
  let(:guest) { double("guest") }
  let(:machine) { double("machine", guest: guest, config: config) }
  let(:networks){ [[:public_network, network_1], [:private_network, network_2]] }
  let(:vm){ double("vm", networks: networks) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".configure_networks" do
    let(:cap) { caps.get(:configure_networks) }

    before do
      allow(guest).to receive(:capability)
        .with(:flavor)
        .and_return(:rhel)

      allow(guest).to receive(:capability)
        .with(:network_scripts_dir)
        .and_return("/scripts")

      allow(guest).to receive(:capability)
        .with(:network_interfaces)
        .and_return(["eth1", "eth2"])
    end

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

    let(:network_3) do
      {
        interface: 2,
        type: "static",
        ip: "33.33.33.11",
        netmask: "255.255.0.0",
        gateway: "33.33.0.1",
      }
    end

    context "network configuration file" do
      let(:networks){ [[:public_network, network_1], [:private_network, network_2], [:private_network, network_3]] }
      let(:tempfile) { double("tempfile") }

      before do
        allow(tempfile).to receive(:binmode)
        allow(tempfile).to receive(:write)
        allow(tempfile).to receive(:fsync)
        allow(tempfile).to receive(:close)
        allow(tempfile).to receive(:path)
        allow(Tempfile).to receive(:open).and_yield(tempfile)
      end

      it "should generate two configuration files" do
        expect(Tempfile).to receive(:open).twice
        cap.configure_networks(machine, [network_1, network_2])
      end

      it "should generate three configuration files" do
        expect(Tempfile).to receive(:open).thrice
        cap.configure_networks(machine, [network_1, network_2, network_3])
      end

      it "should generate configuration with network_2 IP address" do
        expect(tempfile).to receive(:write).with(/#{network_2[:ip]}/)
        cap.configure_networks(machine, [network_1, network_2, network_3])
      end

      it "should generate configuration with network_3 IP address" do
        expect(tempfile).to receive(:write).with(/#{network_3[:ip]}/)
        cap.configure_networks(machine, [network_1, network_2, network_3])
      end
    end

    context "with NetworkManager installed" do
      let(:net1_nm_controlled) { true }
      let(:net2_nm_controlled) { true }

      let(:networks){ [
        [:public_network, network_1.merge(nm_controlled: net1_nm_controlled)],
        [:private_network, network_2.merge(nm_controlled: net2_nm_controlled)]
      ] }

      before do
        allow(cap).to receive(:nmcli?).and_return true
      end

      context "with devices managed by NetworkManager" do
        before do
          allow(cap).to receive(:nm_controlled?).and_return true
        end

        context "with nm_controlled option omitted" do
          let(:networks){ [
            [:public_network, network_1],
            [:private_network, network_2]
          ] }

          it "creates and starts the networks via nmcli" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/nmcli/)
            expect(comm.received_commands[0]).to_not match(/(ifdown|ifup)/)
          end
        end

        context "with nm_controlled option set to true" do
          it "creates and starts the networks via nmcli" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/nmcli/)
            expect(comm.received_commands[0]).to_not match(/(ifdown|ifup)/)
          end
        end

        context "with nm_controlled option set to false" do
          let(:net1_nm_controlled) { false }
          let(:net2_nm_controlled) { false }

          it "creates and starts the networks via ifup and disables devices in NetworkManager" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/nmcli.*disconnect/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to_not match(/ifdown/)
          end
        end

        context "with nm_controlled option set to false on first device" do
          let(:net1_nm_controlled) { false }
          let(:net2_nm_controlled) { true }

          it "creates and starts the networks with one managed manually and one NetworkManager controlled" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/nmcli.*disconnect.*eth1/)
            expect(comm.received_commands[0]).to match(/ifup.*eth1/)
            expect(comm.received_commands[0]).to_not match(/ifdown/)
          end
        end
      end

      context "with devices not managed by NetworkManager" do
        before do
          allow(cap).to receive(:nm_controlled?).and_return false
        end

        context "with nm_controlled option omitted" do
          let(:networks){ [
            [:public_network, network_1],
            [:private_network, network_2]
          ] }

          it "creates and starts the networks manually" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to_not match(/nmcli c up/)
            expect(comm.received_commands[0]).to_not match(/nmcli d disconnect/)
          end
        end

        context "with nm_controlled option set to true" do
          let(:net1_nm_controlled) { true }
          let(:net2_nm_controlled) { true }

          it "creates and starts the networks via nmcli" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/NetworkManager/)
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to_not match(/ifup/)
          end
        end

        context "with nm_controlled option set to false" do
          let(:net1_nm_controlled) { false }
          let(:net2_nm_controlled) { false }

          it "creates and starts the networks via ifup " do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to match(/ifup/)
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to_not match(/nmcli c up/)
            expect(comm.received_commands[0]).to_not match(/nmcli d disconnect/)
          end
        end

        context "with nm_controlled option set to false on first device" do
          let(:net1_nm_controlled) { false }
          let(:net2_nm_controlled) { true }

          it "creates and starts the networks with one managed manually and one NetworkManager controlled" do
            cap.configure_networks(machine, [network_1, network_2])
            expect(comm.received_commands[0]).to_not match(/nmcli.*disconnect/)
            expect(comm.received_commands[0]).to match(/ifdown/)
            expect(comm.received_commands[0]).to match(/ifup.*eth1/)
          end
        end
      end
    end

    context "without NetworkManager installed" do
      before do
        allow(cap).to receive(:nmcli?).and_return false
      end

      context "with nm_controlled option omitted" do

        it "creates and starts the networks manually" do
          cap.configure_networks(machine, [network_1, network_2])
          expect(comm.received_commands[0]).to match(/ifdown/)
          expect(comm.received_commands[0]).to match(/ifup/)
          expect(comm.received_commands[0]).to_not match(/nmcli/)
        end
      end

      context "with nm_controlled option set" do
        let(:networks){ [
          [:public_network, network_1.merge(nm_controlled: true)],
          [:private_network, network_2.merge(nm_controlled: true)]
        ] }

        it "raises an error" do
          expect{ cap.configure_networks(machine, [network_1, network_2]) }.to raise_error(Vagrant::Errors::NetworkManagerNotInstalled)
        end
      end
    end
  end
end
