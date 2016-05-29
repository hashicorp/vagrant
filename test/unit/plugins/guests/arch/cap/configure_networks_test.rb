require_relative "../../../../base"

describe "VagrantPlugins::GuestArch::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestArch::Plugin
      .components
      .guest_capabilities[:arch]
      .get(:configure_networks)
  end

  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    communicator.stub_command("ip -o -0 addr | grep -v LOOPBACK | awk '{print $2}' | sed 's/://'",
      stdout: "eth1\neth2")
  end

  after do
    communicator.verify_expectations!
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
      communicator.expect_command("ip link set eth1 down && netctl restart eth1 && netctl enable eth1")
      communicator.expect_command("ip link set eth2 down && netctl restart eth2 && netctl enable eth2")
      described_class.configure_networks(machine, [network_1, network_2])
    end
  end
end
