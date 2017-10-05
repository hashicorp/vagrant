require_relative "../../../../base"

describe "VagrantPlugins::GuestSolaris11::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestSolaris11::Plugin
      .components
      .guest_capabilities[:solaris11]
  end

  let(:machine) { double("machine", config: double("config", solaris11: double("solaris11", suexec_cmd: 'sudo', device: 'net'))) }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".configufre_networks" do
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

    let(:networks) { [network_1, network_2] }

    it "configures the guests network if static" do
      allow(machine.communicate).to receive(:test).and_return(true)

      cap.configure_networks(machine, networks)
      expect(comm.received_commands[1]).to eq("sudo ipadm delete-addr net1/v4")
      expect(comm.received_commands[2]).to eq("sudo ipadm create-addr -T static -a 33.33.33.10/16 net1/v4")
    end

    it "configures the guests network if dhcp" do
      allow(machine.communicate).to receive(:test).and_return(true)
      cap.configure_networks(machine, networks)
      expect(comm.received_commands[0]).to eq("sudo ipadm create-addr -T addrconf net0/v4")
    end
  end
end
