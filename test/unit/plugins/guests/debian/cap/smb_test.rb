require_relative "../../../../base"

describe "VagrantPlugins::GuestDebian::Cap::SMB" do
  let(:described_class) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
      .get(:smb_install)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".smb_install" do
    it "installs smb when /sbin/mount.cifs does not exist" do
      comm.stub_command("test -f /sbin/mount.cifs", exit_code: 1)
      described_class.smb_install(machine)

      expect(comm.received_commands[1]).to match(/apt-get -yqq update/)
      expect(comm.received_commands[1]).to match(/apt-get -yqq install cifs-utils/)
    end

    it "does not install smb when /sbin/mount.cifs exists" do
      comm.stub_command("test -f /sbin/mount.cifs", exit_code: 0)
      described_class.smb_install(machine)

      expect(comm.received_commands.join("")).to_not match(/update/)
    end
  end
end
