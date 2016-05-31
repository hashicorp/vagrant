require_relative "../../../../base"

describe "VagrantPlugins::GuestAtomic::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestAtomic::Plugin
      .components
      .guest_capabilities[:atomic]
      .get(:docker_daemon_running)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".docker_daemon_running" do
    it "checks /run/docker/sock" do
      described_class.docker_daemon_running(machine)
      expect(comm.received_commands[0]).to eq("test -S /run/docker.sock")
    end
  end
end
