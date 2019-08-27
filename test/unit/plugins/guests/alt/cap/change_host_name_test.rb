require_relative "../../../../base"

describe "VagrantPlugins::GuestALT::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestALT::Plugin
      .components
      .guest_capabilities[:alt]
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
    let(:name) { 'banana-rama.example.com' }
    let(:systemd) { true }
    let(:hostnamectl) { true }
    let(:networkd) { true }
    let(:service) { true }
    let(:network_manager) { false }

    before do
      allow(cap).to receive(:systemd?).and_return(systemd)
      allow(cap).to receive(:service?).and_return(service)
      allow(cap).to receive(:hostnamectl?).and_return(hostnamectl)
      allow(cap).to receive(:systemd_networkd?).and_return(networkd)
      allow(cap).to receive(:systemd_controlled?).with(anything, /NetworkManager/).and_return(network_manager)
    end

    it "sets the hostname if not set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
      cap.change_host_name(machine, name)
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
    end

    context "when hostnamectl is in use" do
      let(:hostnamectl) { true }

      it "sets hostname with hostnamectl" do
        cap.change_host_name(machine, name)
        comm.received_commands.find { |cmd| cmd =~ /^hostnamectl/ }
      end
    end

    context "when hostnamectl is not in use" do
      let(:hostnamectl) { false }

      it "sets hostname with hostname command" do
        cap.change_host_name(machine, name)
        comm.received_commands.find { |cmd| cmd =~ /^hostname -F/ }
      end
    end

    context "restarts the network" do
      context "when networkd is in use" do
        let(:networkd) { true }

        it "restarts networkd with systemctl" do
          cap.change_host_name(machine, name)
          comm.received_commands.find { |cmd| cmd =~ /systemctl restart systemd-networkd/ }
        end
      end

      context "when NetworkManager is in use with systemctl" do
        let(:networkd) { false }
        let(:network_manager) { true }

        it "restarts NetworkManager with systemctl" do
          cap.change_host_name(machine, name)
          comm.received_commands.find { |cmd| cmd =~ /systemctl restart NetworkManager/ }
        end
      end

      context "when NetworkManager is in use without systemctl" do
        let(:networkd) { false }
        let(:network_manager) { true }
        let(:systemd) { false }

        it "restarts NetworkManager without systemctl" do
          cap.change_host_name(machine, name)
          comm.received_commands.find { |cmd| cmd =~ /service NetworkManager restart/ }
        end
      end

      context "when systemd is not in use" do
        let(:networkd) { false }
        let(:network_manager) { false }
        let(:systemd) { false }

        it "restarts networking with networking init script" do
          cap.change_host_name(machine, name)
          comm.received_commands.find { |cmd| cmd =~ /service networking restart/ }
        end
      end

    end

    it "does not change the hostname if already set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
      cap.change_host_name(machine, name)
      expect(comm.received_commands.size).to eq(1)
    end
  end
end
