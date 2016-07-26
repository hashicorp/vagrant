require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::MountSharedFolder" do
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:guest) { double("guest") }

  before do
    allow(machine).to receive(:guest).and_return(guest)
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(guest).to receive(:capability).and_return(nil)
  end
end
