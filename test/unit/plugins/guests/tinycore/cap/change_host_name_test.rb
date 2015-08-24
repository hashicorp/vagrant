require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::GuestTinyCore::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestTinyCore::Plugin.components.guest_capabilities[:tinycore].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) { 'boot2docker' }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    communicator.stub_command('hostname -f', stdout: old_hostname)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do
    it "refreshes the hostname service with the sethostname command" do
      communicator.expect_command(%q(/usr/bin/sethostname newhostname.newdomain.tld))
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end
  end
end
