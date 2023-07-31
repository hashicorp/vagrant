# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
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

  describe "#build_interface_entries" do
    let(:network_0) do
      {
        interface: 0,
        type: "dhcp",
      }
    end

    let(:network_1) do
      {
        interface: 1,
        type: "static",
        ip: "33.33.33.10",
        netmask: "255.255.0.0",
        gateway: "33.33.0.1",
      }
    end
  end

  describe ".configure_networks" do
    let(:cap) { caps.get(:configure_networks) }

    before do
      allow(guest).to receive(:capability).with(:network_interfaces)
        .and_return(["eth1", "eth2"])
    end

    let(:network_0) do
      {
        interface: 0,
        type: "dhcp",
      }
    end

    let(:network_1) do
      {
        interface: 1,
        type: "static",
        ip: "33.33.33.10",
        netmask: "255.255.0.0",
        gateway: "33.33.0.1",
      }
    end

    before do
      allow(comm).to receive(:test).with("nmcli -t d show eth1").and_return(false)
      allow(comm).to receive(:test).with("nmcli -t d show eth2").and_return(false)
      allow(comm).to receive(:test).with("ps -o comm= 1 | grep systemd", {sudo: true}).and_return(false)
      allow(comm).to receive(:test).with("systemctl -q is-active systemd-networkd.service", anything).and_return(false)
      allow(comm).to receive(:test).with("command -v netplan").and_return(false)
    end

    it "creates and starts the networks using net-tools" do
      cap.configure_networks(machine, [network_0, network_1])

      expect(comm.received_commands[0]).to match("/sbin/ifdown 'eth1' || true")
      expect(comm.received_commands[0]).to match("/sbin/ip addr flush dev 'eth1'")
      expect(comm.received_commands[0]).to match("/sbin/ifdown 'eth2' || true")
      expect(comm.received_commands[0]).to match("/sbin/ip addr flush dev 'eth2'")
      expect(comm.received_commands[1]).to match("/sbin/ifup 'eth1'")
      expect(comm.received_commands[1]).to match("/sbin/ifup 'eth2'")

    end

    context "with systemd" do
      before do
        expect(comm).to receive(:test).with("ps -o comm= 1 | grep systemd", {sudo: true}).and_return(true)
        allow(comm).to receive(:test).with("command -v netplan").and_return(false)
      end

      it "creates and starts the networks using net-tools" do
        cap.configure_networks(machine, [network_0, network_1])

        expect(comm.received_commands[0]).to match("/sbin/ifdown 'eth1' || true")
        expect(comm.received_commands[0]).to match("/sbin/ip addr flush dev 'eth1'")
        expect(comm.received_commands[0]).to match("/sbin/ifdown 'eth2' || true")
        expect(comm.received_commands[0]).to match("/sbin/ip addr flush dev 'eth2'")
        expect(comm.received_commands[1]).to match("/sbin/ifup 'eth1'")
        expect(comm.received_commands[1]).to match("/sbin/ifup 'eth2'")
      end

      context "with systemd-networkd" do
        let(:net_conf_dhcp) { "[Match]\nName=eth1\n[Network]\nDHCP=yes" }
        let(:net_conf_static) { "[Match]\nName=eth2\n[Network]\nDHCP=no\nAddress=33.33.33.10/16\nGateway=33.33.0.1" }

        before do
          expect(comm).to receive(:test).with("systemctl -q is-active systemd-networkd.service", anything).and_return(true)
        end

        it "creates and starts the networks using systemd-networkd" do
          cap.configure_networks(machine, [network_0, network_1])

          expect(comm.received_commands[0]).to match("mv -f '/tmp/vagrant-network-entry.*' '/etc/systemd/network/.*network'")
          expect(comm.received_commands[0]).to match("chown")
          expect(comm.received_commands[0]).to match("chmod")
          expect(comm.received_commands[2]).to match("systemctl restart")
        end

        it "properly configures DHCP and static IPs if defined" do
          expect(cap).to receive(:upload_tmp_file).with(comm, net_conf_dhcp)
          expect(cap).to receive(:upload_tmp_file).with(comm, net_conf_static)

          cap.configure_networks(machine, [network_0, network_1])

          expect(comm.received_commands[0]).to match("mkdir -p /etc/systemd/network")
          expect(comm.received_commands[0]).to match("mv -f '' '/etc/systemd/network/50-vagrant-eth1.network'")
          expect(comm.received_commands[0]).to match("chown root:root '/etc/systemd/network/50-vagrant-eth1.network'")
          expect(comm.received_commands[0]).to match("chmod 0644 '/etc/systemd/network/50-vagrant-eth1.network'")
          expect(comm.received_commands[2]).to match("systemctl restart")
        end
      end

      context "with netplan" do
        before do
          expect(comm).to receive(:test).with("command -v netplan").and_return(true)
        end

        let(:nm_yml) { "---\nnetwork:\n  version: 2\n  renderer: NetworkManager\n  ethernets:\n    eth1:\n      dhcp4: true\n    eth2:\n      addresses:\n      - 33.33.33.10/16\n      gateway4: 33.33.0.1\n" }
        let(:networkd_yml) { "---\nnetwork:\n  version: 2\n  renderer: networkd\n  ethernets:\n    eth1:\n      dhcp4: true\n    eth2:\n      addresses:\n      - 33.33.33.10/16\n      gateway4: 33.33.0.1\n" }

        it "uses NetworkManager if detected on device" do
          allow(cap).to receive(:systemd_networkd?).and_return(false)
          allow(cap).to receive(:nmcli?).and_return(true)
          allow(cap).to receive(:nm_controlled?).and_return(true)
          allow(comm).to receive(:test).with("nmcli -t d show eth1").and_return(true)
          allow(comm).to receive(:test).with("nmcli -t d show eth2").and_return(true)

          expect(cap).to receive(:upload_tmp_file).with(comm, nm_yml)
            .and_return("/tmp/vagrant-network-entry.1234")

          cap.configure_networks(machine, [network_0, network_1])


          expect(comm.received_commands[0]).to match("mv -f '/tmp/vagrant-network-entry.*' '/etc/netplan/.*.yaml'")
          expect(comm.received_commands[0]).to match("chown")
          expect(comm.received_commands[0]).to match("chmod")
          expect(comm.received_commands[0]).to match("netplan apply")
        end

        it "raises and error if NetworkManager is detected on device but nmcli is not installed" do
          allow(cap).to receive(:systemd_networkd?).and_return(true)
          allow(cap).to receive(:nmcli?).and_return(false)
          allow(cap).to receive(:nm_controlled?).and_return(true)
          allow(comm).to receive(:test).with("nmcli -t d show eth1").and_return(true)
          allow(comm).to receive(:test).with("nmcli -t d show eth2").and_return(true)

          expect { cap.configure_networks(machine, [network_0, network_1]) }.to raise_error(Vagrant::Errors::NetworkManagerNotInstalled)
        end

        it "creates and starts the networks for systemd with netplan" do
          allow(cap).to receive(:systemd_networkd?).and_return(true)
          expect(cap).to receive(:upload_tmp_file).with(comm, networkd_yml)
            .and_return("/tmp/vagrant-network-entry.1234")

          cap.configure_networks(machine, [network_0, network_1])

          expect(comm.received_commands[0]).to match("mv -f '/tmp/vagrant-network-entry.*' '/etc/netplan/.*.yaml'")
          expect(comm.received_commands[0]).to match("chown")
          expect(comm.received_commands[0]).to match("chmod")
          expect(comm.received_commands[0]).to match("netplan apply")
        end
      end
    end
  end
end
