require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::VagrantPlugins::Cap::Rsync" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:rsync_installed) }
  let(:machine) { double("machine") }
  let(:config) { double("config", smartos: VagrantPlugins::GuestSmartos::Config.new) }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    machine.stub(:communicate).and_return(communicator)
    machine.stub(:config).and_return(config)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".rsync_installed" do
    describe "when rsync is in the path" do
      it "is true" do
        communicator.stub_command("which rsync", stdout: '/usr/bin/rsync', exit_code: 0)
        expect(plugin.rsync_installed(machine)).to be true
      end
    end

    describe "when rsync is not in the path" do
      it "is false" do
        communicator.stub_command("which rsync", stdout: '', exit_code: 1)
        expect(plugin.rsync_installed(machine)).to be false
      end
    end
  end

  describe ".rsync_pre" do
    it 'makes the guestpath directory with pfexec' do
      communicator.expect_command("pfexec mkdir -p '/sync_dir'")
      plugin.rsync_pre(machine, guestpath: '/sync_dir')
    end
  end

  describe ".rsync_post" do
    it 'chowns incorrectly owned files in sync dir' do
      communicator.expect_command("pfexec find '/sync_dir' '(' ! -user somebody -or ! -group somegroup ')' -print0 | pfexec xargs -0 chown somebody:somegroup")
      plugin.rsync_post(machine, guestpath: '/sync_dir', owner: 'somebody', group: 'somegroup')
    end
  end
end

