require_relative "../../../../base"

describe "VagrantPlugins::GuestSmartos::Cap::Halt" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:halt) }
  let(:machine) { double("machine") }
  let(:config) { double("config", smartos: double("smartos", suexec_cmd: 'pfexec')) }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:shutdown_command){ "pfexec /usr/sbin/poweroff" }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:config).and_return(config)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".halt" do
    it "sends a shutdown signal" do
      communicator.expect_command(shutdown_command)
      plugin.halt(machine)
    end

    it "ignores an IOError" do
      communicator.stub_command(shutdown_command, raise: IOError)
      expect {
        plugin.halt(machine)
      }.to_not raise_error
    end

    it "ignores a Vagrant::Errors::SSHDisconnected" do
      communicator.stub_command(shutdown_command, raise: Vagrant::Errors::SSHDisconnected)
      expect {
        plugin.halt(machine)
      }.to_not raise_error
    end
  end
end
