require_relative "../../../../base"

describe "VagrantPlugins::GuestAstra::Cap:RSync" do
  let(:described_class) do
    VagrantPlugins::GuestAstra::Plugin
      .components
      .guest_capabilities[:astra]
      .get(:rsync_install)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".rsync_install" do
    it "installs rsync" do
      described_class.rsync_install(machine)

      expect(comm.received_commands[0]).to match(/apt-get -yqq update/)
      expect(comm.received_commands[0]).to match(/apt-get -yqq install rsync/)
    end
  end
end
