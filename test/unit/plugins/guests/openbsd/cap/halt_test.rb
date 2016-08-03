require_relative "../../../../base"

describe "VagrantPlugins::GuestOpenBSD::Cap::Halt" do
  let(:caps) do
    VagrantPlugins::GuestOpenBSD::Plugin
      .components
      .guest_capabilities[:openbsd]
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
      comm.expect_command("/sbin/shutdown -p -h now")
      cap.halt(machine)
    end

    it "ignores an IOError" do
      comm.stub_command("/sbin/shutdown -p -h now", raise: IOError)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end

    it "ignores a Vagrant::Errors::SSHDisconnected" do
      comm.stub_command("/sbin/shutdown -p -h now", raise: Vagrant::Errors::SSHDisconnected)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end
  end
end
