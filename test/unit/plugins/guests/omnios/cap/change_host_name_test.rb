require_relative "../../../../base"

describe "VagrantPlugins::GuestOmniOS::Cap:RSync" do
  let(:caps) do
    VagrantPlugins::GuestOmniOS::Plugin
      .components
      .guest_capabilities[:omnios]
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

    it "sets the hostname if unset" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
      cap.change_host_name(machine, name)

      expect(comm.received_commands[1]).to match(/echo '#{name}' > \/etc\/nodename/)
      expect(comm.received_commands[1]).to match(/hostname '#{name}'/)
    end

    it "does not set the hostname if set" do
      comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
      cap.change_host_name(machine, name)

      expect(comm.received_commands.size).to eq(1)
    end
  end
end
