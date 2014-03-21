require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::VagrantPlugins::Cap::Halt" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:halt) }
  let(:machine) { double("machine") }
  let(:config) { double("config", smartos: VagrantPlugins::GuestSmartos::Config.new) }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    machine.stub(:communicate).and_return(communicator)
    machine.stub(:config).and_return(config)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".halt" do
    it "sends a shutdown signal" do
      communicator.expect_command(%Q(pfexec /usr/sbin/shutdown -y -i5 -g0))
      plugin.halt(machine)
    end
  end
end

