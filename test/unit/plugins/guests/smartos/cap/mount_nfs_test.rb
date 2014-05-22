require File.expand_path("../../../../../base", __FILE__)

describe "VagrantPlugins::VagrantPlugins::Cap::MountNFS" do
  let(:plugin) { VagrantPlugins::GuestSmartos::Plugin.components.guest_capabilities[:smartos].get(:mount_nfs_folder) }
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

  describe ".mount_nfs_folder" do
    it "creates the directory mount point" do
      communicator.expect_command(%Q(pfexec mkdir -p /mountpoint))
      plugin.mount_nfs_folder(machine, '1.1.1.1', {'nfs' => {guestpath: '/mountpoint'}})
    end

    it "mounts the NFS share" do
      communicator.expect_command(%Q(pfexec /usr/sbin/mount -F nfs '1.1.1.1:/some/share' '/mountpoint'))
      plugin.mount_nfs_folder(machine, '1.1.1.1', {'nfs' => {guestpath: '/mountpoint', hostpath: '/some/share'}})
    end
  end
end

