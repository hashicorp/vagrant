require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::NFSClient" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
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
    let(:cap) { caps.get(:nfs_client_install) }

    it "installs nfs client utilities" do
      cap.nfs_client_install(machine)
      expect(comm.received_commands[0]).to match(/zypper -n install nfs-client/)
      expect(comm.received_commands[0]).to match(/service rpcbind restart/)
      expect(comm.received_commands[0]).to match(/service nfs restart/)
    end
  end
end
