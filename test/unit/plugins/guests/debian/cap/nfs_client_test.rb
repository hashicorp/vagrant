require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::NFSClient" do
  let(:described_class) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
      .get(:nfs_client_install)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".nfs_client_install" do
    it "installs nfs client utilities" do
      described_class.nfs_client_install(machine)

      expect(comm.received_commands[0]).to match(/apt-get -yqq update/)
      expect(comm.received_commands[0]).to match(/apt-get -yqq install nfs-common portmap/)
    end
  end
end
