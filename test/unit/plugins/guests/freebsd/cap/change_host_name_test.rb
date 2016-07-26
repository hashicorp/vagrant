require_relative "../../../../base"

describe "VagrantPlugins::GuestFreeBSD::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestFreeBSD::Plugin
      .components
      .guest_capabilities[:freebsd]
      .get(:change_host_name)
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
    let(:name) { "banana-rama.example.com" }

    it "sets the hostname and /etc/hosts" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
      described_class.change_host_name(machine, name)

      expect(comm.received_commands[1]).to match(/hostname '#{name}'/)
      expect(comm.received_commands[1]).to match(/grep -w '#{name}' \/etc\/hosts/)
      expect(comm.received_commands[1]).to match(/echo -e '127.0.0.1\\t#{name}\\tbanana-rama'/)
    end

    it "does nothing if the hostname is already set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
      described_class.change_host_name(machine, name)
      expect(comm.received_commands.size).to eq(1)
    end
  end
end
