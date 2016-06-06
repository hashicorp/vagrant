require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::RSync" do
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

  describe ".rsync_install" do
    let(:cap) { caps.get(:rsync_install) }

    it "installs rsync" do
      comm.expect_command("zypper -n install rsync")
      cap.rsync_install(machine)
    end
  end

  describe ".rsync_installed" do
    let(:cap) { caps.get(:rsync_installed) }

    it "checks if rsync is installed" do
      comm.expect_command("test -f /usr/bin/rsync")
      cap.rsync_installed(machine)
    end
  end
end
