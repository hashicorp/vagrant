# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
  end

  let(:machine) { double("machine", name: "guestname") }
  let(:logger) { double("logger", debug: true) }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    let(:cap) { caps.get(:change_host_name) }
    let(:name) { 'banana-rama.example.com' }
    let(:systemd) { true }
    let(:hostnamectl) { true }
    let(:networkd) { true }
    let(:network_manager) { false }
    let(:networks) { [
      [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]
    ] }

    before do
      allow(cap).to receive(:systemd?).and_return(systemd)
      allow(cap).to receive(:hostnamectl?).and_return(hostnamectl)
      allow(cap).to receive(:systemd_networkd?).and_return(networkd)
      allow(cap).to receive(:systemd_controlled?).with(anything, /NetworkManager/).and_return(network_manager)
      allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
      allow(cap).to receive(:add_hostname_to_loopback_interface)
      allow(cap).to receive(:replace_host)
    end

    context "minimal network config" do
      it "sets the hostname if not set" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
        cap.change_host_name(machine, name)
        expect(comm.received_commands[1]).to match(/echo 'banana-rama' > \/etc\/hostname/)
      end

      it "sets the hostname if not set" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
        cap.change_host_name(machine, name)
        expect(comm.received_commands[1]).to_not match(/echo 'banana-rama' > \/etc\/hostname/)
      end
    end

    context "multiple networks configured with hostname" do 
      it "adds a new entry only for the hostname" do 
        networks = [
          [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
          [:public_network, {:ip=>"192.168.0.1", :hostname=>true, :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
          [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
        expect(cap).to receive(:replace_host)
        expect(cap).to_not receive(:add_hostname_to_loopback_interface)
        cap.change_host_name(machine, name)
      end

      it "appends an entry to the loopback interface" do 
        networks = [
          [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
          [:public_network, {:ip=>"192.168.0.1", :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
          [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
        expect(cap).to_not receive(:replace_host)
        expect(cap).to receive(:add_hostname_to_loopback_interface).once
        cap.change_host_name(machine, name)
      end
    end

    context "when hostnamectl is in use" do
      let(:hostnamectl) { true }

      it "sets hostname with hostnamectl" do
        cap.change_host_name(machine, name)
        expect(comm.received_commands[2]).to match(/hostnamectl/)
      end
    end

    context "when hostnamectl is not in use" do
      let(:hostnamectl) { false }

      it "sets hostname with hostname command" do
        cap.change_host_name(machine, name)
        expect(comm.received_commands[2]).to match(/hostname -F/)
      end
    end

    context "restarts the network" do
      context "when networkd is in use" do
        let(:networkd) { true }

        it "restarts networkd with systemctl" do
          cap.change_host_name(machine, name)
          expect(comm.received_commands[3]).to match(/systemctl restart systemd-networkd/)
        end
      end

      context "when NetworkManager is in use" do
        let(:networkd) { false }
        let(:network_manager) { true }

        it "restarts NetworkManager with systemctl" do
          cap.change_host_name(machine, name)
          expect(comm.received_commands[3]).to match(/systemctl restart NetworkManager/)
        end
      end

      context "when networkd and NetworkManager are not in use" do
        let(:networkd) { false }
        let(:network_manager) { false }
        let(:systemd) { true }

        it "restarts the network using systemctl" do
          expect(cap).to receive(:restart_each_interface).
            with(machine, anything)
          cap.change_host_name(machine, name)
        end

        it "restarts networking with networking init script" do
          expect(cap).to receive(:restart_each_interface).
            with(machine, anything)
          cap.change_host_name(machine, name)
        end
      end

      context "when systemd is not in use" do
        let(:systemd) { false }

        it "restarts the network using service" do
          expect(cap).to receive(:restart_each_interface).
            with(machine, anything)
          cap.change_host_name(machine, name)
        end

        it "restarts the network using ifdown/ifup" do
          expect(cap).to receive(:restart_each_interface).
            with(machine, anything)
          cap.change_host_name(machine, name)
        end
      end
    end

    it "does not set the hostname if unset" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
      expect(cap).to_not receive(:add_hostname_to_loopback_interface)
      expect(cap).to_not receive(:replace_host)
      cap.change_host_name(machine, name)
    end
  end

  describe ".restart_each_interface" do
    let(:cap) { caps.get(:change_host_name) }
    let(:systemd) { true }
    let(:interfaces) { ["eth0", "eth1", "eth2"] }

    before do
      allow(cap).to receive(:systemd?).and_return(systemd)
      allow(VagrantPlugins::GuestLinux::Cap::NetworkInterfaces).to receive(:network_interfaces).
        and_return(interfaces)
    end

    context "with nettools" do
      let(:systemd) { false }

      it "restarts every interface" do
        cap.send(:restart_each_interface, machine, logger)
        expect(comm.received_commands[0]).to match(/ifdown eth0;ifup eth0/)
        expect(comm.received_commands[1]).to match(/ifdown eth1;ifup eth1/)
        expect(comm.received_commands[2]).to match(/ifdown eth2;ifup eth2/)
      end
    end

    context "with systemctl" do
      it "restarts every interface" do
        cap.send(:restart_each_interface, machine, logger)
        expect(comm.received_commands[0]).to match(/systemctl stop ifup@eth0.service;systemctl start ifup@eth0.service/)
        expect(comm.received_commands[1]).to match(/systemctl stop ifup@eth1.service;systemctl start ifup@eth1.service/)
        expect(comm.received_commands[2]).to match(/systemctl stop ifup@eth2.service;systemctl start ifup@eth2.service/)
      end
    end
  end
end
