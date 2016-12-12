require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/windows/cap/change_host_name")

describe "VagrantPlugins::GuestWindows::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do

    let(:rename_script) { <<-EOH
        $computer = Get-WmiObject -Class Win32_ComputerSystem
        $retval = $computer.rename("newhostname").returnvalue
        if ($retval -eq 0) {
          shutdown /r /t 5 /f /d p:4:1 /c "Vagrant Rename Computer"
        }
        exit $retval
      EOH
      }

    it "changes the hostname" do
      communicator.stub_command(
        'if (!([System.Net.Dns]::GetHostName() -eq \'newhostname\')) { exit 0 } exit 1',
        exit_code: 0)
      communicator.stub_command(rename_script, exit_code: 0)
      described_class.change_host_name_and_wait(machine, 'newhostname', 0)
    end

  end
end
