require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
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

    it "sets the hostname" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
      described_class.change_host_name(machine, name)
      expect(comm.received_commands[1]).to match(/scutil --set ComputerName 'banana-rama.example.com'/)
      expect(comm.received_commands[1]).to match(/scutil --set HostName 'banana-rama.example.com'/)
      expect(comm.received_commands[1]).to match(/scutil --set LocalHostName 'banana-rama'/)
      expect(comm.received_commands[1]).to match(/hostname 'banana-rama.example.com'/)
    end

    it "does not change the hostname if already set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
      described_class.change_host_name(machine, name)
      expect(comm.received_commands.size).to eq(1)
    end
  end
end
