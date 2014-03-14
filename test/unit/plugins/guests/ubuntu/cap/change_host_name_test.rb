require File.expand_path("../../../../../base", __FILE__)
require File.expand_path("../../../support/shared/debian_like_host_name_examples", __FILE__)

describe "VagrantPlugins::GuestUbuntu::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestUbuntu::Plugin.components.guest_capabilities[:ubuntu].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) {'oldhostname.olddomain.tld' }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    communicator.stub_command('hostname -f', stdout: old_hostname)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do
    it_behaves_like "a debian-like host name change"

    it "refreshes the hostname service with upstart" do
      communicator.expect_command(%q(service hostname start))
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end

    it "renews dhcp on the system with the new hostname (with hotplug allowed)" do
      communicator.expect_command(%q(ifdown -a; ifup -a; ifup -a --allow=hotplug))
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end
  end
end
