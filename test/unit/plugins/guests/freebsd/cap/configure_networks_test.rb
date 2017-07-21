require_relative "../../../../base"

describe "VagrantPlugins::GuestFreeBSD::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestFreeBSD::Plugin
      .components
      .guest_capabilities[:freebsd]
      .get(:configure_networks)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    comm.stub_command("ifconfig -a | grep -o '^[0-9a-z]*' | grep -v '^lo'",
      stdout: "em1\nem2")
  end

  after do
    comm.verify_expectations!
  end

  describe ".configure_networks" do
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
      described_class.configure_networks(machine, [network_1, network_2])
      expect(comm.received_commands[1]).to match(/dhclient 'em1'/)
      expect(comm.received_commands[1]).to match(/\/etc\/rc.d\/netif restart 'em1'/)

      expect(comm.received_commands[1]).to_not match(/dhclient 'em2'/)
      expect(comm.received_commands[1]).to match(/\/etc\/rc.d\/netif restart 'em2'/)
    end
  end
end
