require_relative "../../../../base"

describe "VagrantPlugins::GuestTinyCore::Cap::Halt" do
  let(:caps) do
    VagrantPlugins::GuestTinyCore::Plugin
      .components
      .guest_capabilities[:tinycore]
  end

  let(:shutdown_command){ "poweroff" }
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
      comm.expect_command(shutdown_command)
      cap.halt(machine)
    end

    it "ignores an IOError" do
      comm.stub_command(shutdown_command, raise: IOError)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end

    it "ignores a Vagrant::Errors::SSHDisconnected" do
      comm.stub_command(shutdown_command, raise: Vagrant::Errors::SSHDisconnected)
      expect {
        cap.halt(machine)
      }.to_not raise_error
    end
  end
end
