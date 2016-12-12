require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::Halt" do
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

  describe ".halt" do
    let(:cap) { caps.get(:halt) }

    it "runs the shutdown command" do
      comm.expect_command("/sbin/shutdown -h now")
      cap.halt(machine)
    end

    it "does not raise an IOError" do
      comm.stub_command("shutdown -h now", raise: IOError)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end

    it "ignores a Vagrant::Errors::SSHDisconnected" do
      comm.stub_command("shutdown -h now", raise: Vagrant::Errors::SSHDisconnected)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end
  end
end
