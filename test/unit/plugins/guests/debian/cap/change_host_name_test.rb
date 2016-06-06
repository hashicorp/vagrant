require_relative "../../../../base"
require_relative "../../support/shared/debian_like_host_name_examples"

describe "VagrantPlugins::GuestDebian::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestDebian::Plugin
      .components
      .guest_capabilities[:debian]
      .get(:change_host_name)
  end

  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) { 'oldhostname.olddomain.tld' }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    communicator.stub_command('hostname -f', stdout: old_hostname)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do
    it_behaves_like "a debian-like host name change"

    it "does nothing when the provided hostname is not different" do
      described_class.change_host_name(machine, 'oldhostname.olddomain.tld')
      expect(communicator.received_commands).to eq(['hostname -f'])
    end

    it "refreshes the hostname service with the hostname command" do
      communicator.expect_command(%q(hostname -F /etc/hostname))
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end

    it "renews dhcp on the system with the new hostname" do
      communicator.expect_command(%q(ifdown -a; ifup -a; ifup eth0))
      described_class.change_host_name(machine, 'newhostname.newdomain.tld')
    end
  end
end
