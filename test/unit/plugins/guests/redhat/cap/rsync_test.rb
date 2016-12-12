require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap:RSync" do
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

  describe ".rsync_install" do
    let(:cap) { caps.get(:rsync_install) }

    it "installs rsync" do
      cap.rsync_install(machine)
      expect(comm.received_commands[0]).to match(/install rsync/)
    end
  end
end
