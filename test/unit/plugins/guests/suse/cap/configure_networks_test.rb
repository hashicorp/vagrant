require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    comm.stub_command("ip -o -0 addr | grep -v LOOPBACK | awk '{print $2}' | sed 's/://'",
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

    let(:guest) { double("guest") }

    before do
      allow(machine).to receive(:guest).and_return(guest)
      allow(guest).to receive(:capability)
        .with(:network_scripts_dir)
        .and_return("/scripts")
    end

    it "creates and starts the networks" do
      cap.configure_networks(machine, [network_1, network_2])
      expect(comm.received_commands[1]).to match(/\/sbin\/ifdown 'eth1'/)
      expect(comm.received_commands[1]).to match(/\/sbin\/ifup 'eth1'/)
      expect(comm.received_commands[1]).to match(/\/sbin\/ifdown 'eth2'/)
      expect(comm.received_commands[1]).to match(/\/sbin\/ifup 'eth2'/)
    end
  end
end
