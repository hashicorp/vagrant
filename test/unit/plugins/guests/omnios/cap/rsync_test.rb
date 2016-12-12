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

  describe ".rsync_install" do
    let(:cap) { caps.get(:rsync_install) }

    it "installs rsync" do
      cap.rsync_install(machine)
      expect(comm.received_commands[0]).to match(/pkg install rsync/)
    end
  end
end
