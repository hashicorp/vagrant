require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::VagrantPlugins::Cap::Rsync" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:rsync_install) }
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

  describe ".rsync_install" do
    let(:username) { "some_user" }

    before do
      machine.stub(:ssh_info).and_return({username: username})
    end

    it "creates a local directory" do
      communicator.expect_command(%Q(pfexec mkdir -p '/mountpoint'))
      plugin.rsync_install(machine, {guestpath: '/mountpoint'})
    end

    it "chowns local directory to ssh user" do
      communicator.expect_command(%Q(pfexec chown -R #{username} '/mountpoint'))
      plugin.rsync_install(machine, {guestpath: '/mountpoint'})
    end
  end
end

