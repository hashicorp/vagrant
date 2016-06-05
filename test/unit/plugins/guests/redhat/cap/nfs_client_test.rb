require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap:NFSClient" do
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

  describe ".nfs_client_install" do
    let(:cap) { caps.get(:nfs_client_install) }

    it "installs rsync" do
      cap.nfs_client_install(machine)
      expect(comm.received_commands[0]).to match(/install nfs-utils nfs-utils-lib portmap/)
      expect(comm.received_commands[0]).to match(/\/bin\/systemctl restart rpcbind nfs/)
    end
  end
end
