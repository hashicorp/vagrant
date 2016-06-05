require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
      .get(:configure_networks)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".configure_networks" do
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

    it "creates and starts the networks" do
      described_class.configure_networks(machine, [network_0, network_1])

      expect(comm.received_commands[0]).to match("/sbin/ifdown 'eth0' 2> /dev/null || true")
      expect(comm.received_commands[0]).to match("/sbin/ip addr flush dev 'eth0' 2> /dev/null")
      expect(comm.received_commands[0]).to match("/sbin/ifdown 'eth1' 2> /dev/null || true")
      expect(comm.received_commands[0]).to match("/sbin/ip addr flush dev 'eth1' 2> /dev/null")
      expect(comm.received_commands[0]).to match("/sbin/ifup 'eth0'")
      expect(comm.received_commands[0]).to match("/sbin/ifup 'eth1'")
    end
  end
end
