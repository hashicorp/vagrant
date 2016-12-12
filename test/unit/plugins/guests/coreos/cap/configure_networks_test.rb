require_relative "../../../../base"

describe "VagrantPlugins::GuestCoreOS::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestCoreOS::Plugin
      .components
      .guest_capabilities[:coreos]
      .get(:configure_networks)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  let(:env) do
    double("env", machine: machine, active_machines: [machine])
  end

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:env).and_return(env)

    allow(described_class).to receive(:get_ip).and_return("1.2.3.4")

    comm.stub_command("ifconfig | grep '(e[n,t][h,s,p][[:digit:]]([a-z][[:digit:]])?' | cut -f1 -d:",
      stdout: "eth1\neth2")
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
      expect(comm.received_commands[1]).to match(/systemctl stop etcd/)
      expect(comm.received_commands[1]).to match(/ifconfig eth1 netmask/)
      expect(comm.received_commands[1]).to match(/ifconfig eth2 33.33.33.10 netmask 255.255.0.0/)
      expect(comm.received_commands[1]).to match(/systemctl restart local-enable.service/)
      expect(comm.received_commands[1]).to match(/systemctl start etcd/)
    end
  end
end
