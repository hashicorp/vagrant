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

    before do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: hostname_changed ? 1 : 0)
      allow(cap).to receive(:systemd?).and_return(systemd)
      allow(cap).to receive(:hostnamectl?).and_return(hostnamectl)
      allow(cap).to receive(:systemd_networkd?).and_return(networkd)
      allow(cap).to receive(:systemd_controlled?).with(anything, /NetworkManager/).and_return(network_manager)
    end

    it "sets the hostname" do
      cap.change_host_name(machine, name)
      expect(comm.received_commands[1]).to match(/\/etc\/sysconfig\/network/)
      expect(comm.received_commands[1]).to match(/\/etc\/sysconfig\/network-scripts\/ifcfg/)
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
        expect(comm.received_commands.size).to eq(1)
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
