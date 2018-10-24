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

    before do
      allow(cap).to receive(:systemd?).and_return(systemd)
      allow(cap).to receive(:hostnamectl?).and_return(hostnamectl)
      allow(cap).to receive(:systemd_networkd?).and_return(networkd)
      allow(cap).to receive(:systemd_controlled?).with(anything, /NetworkManager/).and_return(network_manager)
    end

    it "sets the hostname if not set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
      cap.change_host_name(machine, name)
      expect(comm.received_commands[1]).to match(/echo 'banana-rama' > \/etc\/hostname/)
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
      cap.change_host_name(machine, name)
      expect(comm.received_commands.size).to eq(1)
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
