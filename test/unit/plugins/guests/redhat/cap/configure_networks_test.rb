require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
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

    let(:network_scripts_dir) { "/" }

    let(:capability) { double("capability") }

    before do
      allow(machine).to receive(:guest).and_return(capability)
      allow(capability).to receive(:capability)
        .with(:network_scripts_dir)
        .and_return(network_scripts_dir)
    end

    it "uses fedora for rhel7 configuration" do
      require_relative "../../../../../../plugins/guests/fedora/cap/configure_networks"

      allow(capability).to receive(:capability)
        .with(:flavor)
        .and_return(:rhel_7)
      allow(VagrantPlugins::GuestFedora::Cap::ConfigureNetworks)
        .to receive(:configure_networks)

      expect(VagrantPlugins::GuestFedora::Cap::ConfigureNetworks)
        .to receive(:configure_networks).once
      cap.configure_networks(machine, [network_1, network_2])
    end

    it "creates and starts the networks" do
      allow(capability).to receive(:capability)
        .with(:flavor)
        .and_return(:rhel)

      cap.configure_networks(machine, [network_1, network_2])
      expect(comm.received_commands[1]).to match(/\/sbin\/ifdown 'eth1'/)
      expect(comm.received_commands[1]).to match(/\/sbin\/ifup 'eth1'/)
      expect(comm.received_commands[1]).to match(/\/sbin\/ifdown 'eth2'/)
      expect(comm.received_commands[1]).to match(/\/sbin\/ifup 'eth2'/)
    end
  end
end
