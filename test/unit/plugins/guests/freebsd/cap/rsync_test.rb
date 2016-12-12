require_relative "../../../../base"

describe "VagrantPlugins::GuestFreeBSD::Cap::RSync" do
  let(:caps) do
    VagrantPlugins::GuestFreeBSD::Plugin
      .components
      .guest_capabilities[:freebsd]
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

    it "installs rsync" do
      comm.expect_command("pkg install -y rsync")
      cap.rsync_install(machine)
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
