require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/windows/cap/halt")

describe "VagrantPlugins::GuestWindows::Cap::Halt" do
  let(:described_class) do
    VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:halt)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".halt" do
  
    it "cancels any existing scheduled shut down" do
      communicator.expect_command("shutdown -a")
      described_class.halt(machine)
    end

    it "shuts down immediately" do
      communicator.expect_command('shutdown /s /t 1 /c "Vagrant Halt" /f /d p:4:1')
      described_class.halt(machine)
    end

  end
end
