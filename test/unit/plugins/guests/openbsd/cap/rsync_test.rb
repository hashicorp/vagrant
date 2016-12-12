require_relative "../../../../base"

describe "VagrantPlugins::GuestOpenBSD::Cap::RSync" do
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

  describe ".rsync_install" do
    let(:cap) { caps.get(:rsync_install) }

    describe "successful installation" do
      it "installs rsync" do
        cap.rsync_install(machine)
        expect(comm.received_commands[0]).to match(/pkg_add -I rsync/)
        expect(comm.received_commands[1]).to match(/pkg_info/)
      end
    end

    describe "failure installation" do
      before do
        expect(comm).to receive(:execute).and_raise(Vagrant::Errors::RSyncNotInstalledInGuest, {command: '', output: ''})
      end

      it "raises custom exception" do
        expect{ cap.rsync_install(machine) }.to raise_error(Vagrant::Errors::RSyncNotInstalledInGuest)
      end
    end
  end

  describe ".rsync_installed" do
    let(:cap) { caps.get(:rsync_installed) }

    it "checks if rsync is installed" do
      comm.expect_command("which rsync")
      cap.rsync_installed(machine)
    end
  end

  describe ".rsync_command" do
    let(:cap) { caps.get(:rsync_command) }

    it "defaults to 'sudo rsync'" do
      expect(cap.rsync_command(machine)).to eq("sudo rsync")
    end
  end
end
