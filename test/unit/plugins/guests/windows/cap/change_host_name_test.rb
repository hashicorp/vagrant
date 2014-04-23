require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/guests/windows/cap/change_host_name")

describe "VagrantPlugins::GuestWindows::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) {'oldhostname.olddomain.tld' }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do
  
    it "changes the hostname" do
      communicator.expect_command('wmic computersystem where name="%COMPUTERNAME%" call rename name="newhostname.newdomain.tld"')
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end

  end
end
