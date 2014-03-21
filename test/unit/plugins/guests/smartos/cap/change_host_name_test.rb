require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::VagrantPlugins::Cap::ChangeHostName" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:change_host_name) }
  let(:machine) { double("machine") }
  let(:config) { double("config", smartos: VagrantPlugins::GuestSmartos::Config.new) }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:old_hostname) { 'oldhostname.olddomain.tld' }
  let(:new_hostname) { 'newhostname.olddomain.tld' }

  before do
    machine.stub(:communicate).and_return(communicator)
    machine.stub(:config).and_return(config)
    communicator.stub_command("hostname | grep '#{old_hostname}'", stdout: old_hostname)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".change_host_name" do
    it "refreshes the hostname service with the hostname command" do
      communicator.expect_command(%Q(pfexec hostname #{new_hostname}))
      plugin.change_host_name(machine, new_hostname)
    end

    it "writes the hostname into /etc/nodename" do
      communicator.expect_command(%Q(pfexec sh -c "echo '#{new_hostname}' > /etc/nodename"))
      plugin.change_host_name(machine, new_hostname)
    end
  end
end

