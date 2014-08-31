require File.expand_path("../../../../../base", __FILE__)
require File.expand_path("../../../support/shared/redhat_like_host_name_examples", __FILE__)

describe "VagrantPlugins::GuestRedHat::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestRedHat::Plugin.components.guest_capabilities[:redhat].get(:change_host_name)
  end
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:guest) { double("guest") }

  before do
    allow(guest).to receive(:capability).and_return(nil)
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:guest).and_return(guest)
    communicator.stub_command('hostname -f', stdout: old_hostname)
    communicator.expect_command('hostname -f')
  end

  after do
    communicator.verify_expectations!
  end

  context 'when oldhostname is qualified' do
    let(:old_hostname) { 'oldhostname.olddomain.tld' }
    let(:similar_hostname) {'oldhostname'}

    it_behaves_like 'a full redhat-like host name change'

    include_examples 'inserting hostname in /etc/hosts'
    include_examples 'swapping simple hostname in /etc/hosts'
    include_examples 'swapping qualified hostname in /etc/hosts'
  end

  context 'when oldhostname is simple' do
    let(:old_hostname) { 'oldhostname' }
    let(:similar_hostname) {'oldhostname.olddomain.tld'}

    it_behaves_like 'a full redhat-like host name change'

    include_examples 'inserting hostname in /etc/hosts'
    include_examples 'swapping simple hostname in /etc/hosts'

    context 'and is only able to be determined by hostname (without -f)' do
      before do
        communicator.stub_command('hostname -f',nil)
        communicator.stub_command('hostname', stdout: old_hostname)
        communicator.expect_command('hostname')
      end

      it_behaves_like 'a full redhat-like host name change'

      include_examples 'inserting hostname in /etc/hosts'
      include_examples 'swapping simple hostname in /etc/hosts'
    end
  end

  context 'when the short version of hostname is localhost' do
    let(:old_hostname) { 'localhost.olddomain.tld' }

    it_behaves_like 'a partial redhat-like host name change'

    include_examples 'inserting hostname in /etc/hosts'

    it "does more even when the provided hostname is not different" do
      described_class.change_host_name(machine, old_hostname)
      expect(communicator.received_commands.to_set).not_to eq(communicator.expected_commands.keys.to_set)
    end
  end
end
