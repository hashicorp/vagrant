require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
      .get(:configure_networks)
  end

  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
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
      communicator.expect_command("/sbin/ifdown eth0 2> /dev/null || true")
      communicator.expect_command("/sbin/ip addr flush dev eth0 2> /dev/null")
      communicator.expect_command("/sbin/ifdown eth1 2> /dev/null || true")
      communicator.expect_command("/sbin/ip addr flush dev eth1 2> /dev/null")
      communicator.expect_command("/sbin/ifup eth0")
      communicator.expect_command("/sbin/ifup eth1")
      described_class.configure_networks(machine, [network_0, network_1])
    end
  end
end
