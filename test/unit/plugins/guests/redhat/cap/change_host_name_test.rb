# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
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
    let(:name) { "banana-rama.example.com" }
    let(:hostname_changed) { true }
    let(:systemd) { true }
    let(:hostnamectl) { true }
    let(:networkd) { true }
    let(:network_manager) { false }
    let(:networks) { [
      [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]
    ] }

    before do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: hostname_changed ? 1 : 0)
      allow(cap).to receive(:systemd?).and_return(systemd)
      allow(cap).to receive(:hostnamectl?).and_return(hostnamectl)
      allow(cap).to receive(:systemd_networkd?).and_return(networkd)
      allow(cap).to receive(:systemd_controlled?).with(anything, /NetworkManager/).and_return(network_manager)
      allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
    end

    context "minimal network config" do 
      it "sets the hostname" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
        cap.change_host_name(machine, name)
        expect(comm.received_commands[1]).to match(/\/etc\/sysconfig\/network/)
      end

      it "does not change the hostname if already set" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
        cap.change_host_name(machine, name)
        expect(comm).to_not receive(:sudo).with(/\/etc\/sysconfig\/network/)
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

    context "when host name is already set" do
      let(:hostname_changed) { false }

      it "does not change the hostname" do
        cap.change_host_name(machine, name)
        expect(comm.received_commands.size).to eq(2)
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

        it "restarts the network using service" do
          cap.change_host_name(machine, name)
          expect(comm.received_commands[3]).to match(/service network restart/)
        end
      end

      context "when systemd is not in use" do
        let(:systemd) { false }

        it "restarts the network using service" do
          cap.change_host_name(machine, name)
          expect(comm.received_commands[3]).to match(/service network restart/)
        end
      end
    end
  end
end
