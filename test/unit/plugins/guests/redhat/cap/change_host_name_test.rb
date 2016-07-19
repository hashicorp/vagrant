require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    let(:cap) { caps.get(:change_host_name) }

    let(:name) { "banana-rama.example.com" }

    it "sets the hostname" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)

      cap.change_host_name(machine, name)
      expect(comm.received_commands[1]).to match(/\/etc\/sysconfig\/network/)
      expect(comm.received_commands[1]).to match(/\/etc\/sysconfig\/network-scripts\/ifcfg/)
      expect(comm.received_commands[1]).to match(/hostnamectl set-hostname --static '#{name}'/)
      expect(comm.received_commands[1]).to match(/hostnamectl set-hostname --transient '#{name}'/)
      expect(comm.received_commands[1]).to match(/service network restart/)
    end

    it "does not change the hostname if already set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
      cap.change_host_name(machine, name)
      expect(comm.received_commands.size).to eq(1)
    end
  end
end
