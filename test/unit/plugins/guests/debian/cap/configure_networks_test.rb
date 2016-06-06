require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
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
      cap.configure_networks(machine, [network_0, network_1])

      expect(comm.received_commands[1]).to match("/sbin/ifdown 'eth1' || true")
      expect(comm.received_commands[1]).to match("/sbin/ip addr flush dev 'eth1'")
      expect(comm.received_commands[1]).to match("/sbin/ifdown 'eth2' || true")
      expect(comm.received_commands[1]).to match("/sbin/ip addr flush dev 'eth2'")
      expect(comm.received_commands[1]).to match("/sbin/ifup 'eth1'")
      expect(comm.received_commands[1]).to match("/sbin/ifup 'eth2'")
    end
  end
end
