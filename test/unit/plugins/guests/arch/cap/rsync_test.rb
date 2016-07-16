require_relative "../../../../base"

describe "VagrantPlugins::GuestArch::Cap:RSync" do
  let(:described_class) do
    VagrantPlugins::GuestArch::Plugin
      .components
      .guest_capabilities[:arch]
      .get(:rsync_install)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".rsync_install" do
    it "installs rsync when not installed" do
      comm.stub_command("test -f /usr/bin/rsync", exit_code: 1)
      described_class.rsync_install(machine)

      expect(comm.received_commands[1]).to match(/pacman -Sy --noconfirm/)
      expect(comm.received_commands[1]).to match(/pacman -S --noconfirm rsync/)
    end

    it "does not install rsync when installed" do
      comm.stub_command("test -f /usr/bin/rsync", exit_code: 0)
      described_class.rsync_install(machine)

      expect(comm.received_commands.join("")).to_not match(/-S/)
    end
  end
end
