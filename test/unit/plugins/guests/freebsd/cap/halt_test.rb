require_relative "../../../../base"

describe "VagrantPlugins::GuestFreeBSD::Cap::Halt" do
  let(:described_class) do
    VagrantPlugins::GuestFreeBSD::Plugin
      .components
      .guest_capabilities[:freebsd]
      .get(:halt)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".halt" do
    it "runs the shutdown command" do
      comm.expect_command("shutdown -p now")
      described_class.halt(machine)
    end

    it "does not raise an IOError" do
      comm.stub_command("shutdown -p now", raise: IOError)
      expect {
        described_class.halt(machine)
      }.to_not raise_error
    end
  end
end
