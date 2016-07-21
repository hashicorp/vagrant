require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::Halt" do
  let(:caps) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
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
    let(:cap) { caps.get(:halt) }

    it "runs the shutdown command" do
      comm.expect_command("/sbin/shutdown -h now")
      cap.halt(machine)
    end

    it "ignores an IOError" do
      comm.stub_command("/sbin/shutdown -h now", raise: IOError)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end
  end
end
