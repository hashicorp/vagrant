require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/guests/windows/cap/change_host_name")

describe "VagrantPlugins::GuestWindows::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) { 'oldhostname' }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do
    it "changes the hostname" do
      communicator.stub_command('if (!($env:ComputerName -eq \'newhostname\')) { exit 0 } exit 1', exit_code: 0)
      communicator.stub_command('netdom renamecomputer "$Env:COMPUTERNAME" /NewName:newhostname /Force /Reboot:0',
        exit_code: 0)
      described_class.change_host_name_and_wait(machine, 'newhostname', 0)
    end

    it "raises RenameComputerFailed when exit code is non-zero" do
      communicator.stub_command('if (!($env:ComputerName -eq \'newhostname\')) { exit 0 } exit 1', exit_code: 0)
      communicator.stub_command('netdom renamecomputer "$Env:COMPUTERNAME" /NewName:newhostname /Force /Reboot:0',
        exit_code: 123)
      expect { described_class.change_host_name_and_wait(machine, 'newhostname', 0) }.
        to raise_error(VagrantPlugins::GuestWindows::Errors::RenameComputerFailed)
    end
  end
end
