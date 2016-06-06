require_relative "../../../../base"

describe "VagrantPlugins::GuestSlackware::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestSlackware::Plugin
      .components
      .guest_capabilities[:slackware]
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

    it "creates and starts the networks" do
      cap.configure_networks(machine, [network_1, network_2])
      expect(comm.received_commands[1]).to match(/\/etc\/rc.d\/rc.inet1/)
    end
  end
end
