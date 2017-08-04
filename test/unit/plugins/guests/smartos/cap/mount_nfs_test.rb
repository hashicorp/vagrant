require_relative "../../../../base"
require_relative "../../../../../../plugins/guests/smartos/config"

describe "VagrantPlugins::GuestSmartos::Cap::MountNFS" do
  let(:caps) do
    VagrantPlugins::GuestSmartos::Plugin
        .components
        .guest_capabilities[:smartos]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config) { double("config", smartos: VagrantPlugins::GuestSmartos::Config.new) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:config).and_return(config)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_nfs_folder" do
    let(:cap) { caps.get(:mount_nfs_folder) }

    it "mounts the folder" do
      cap.mount_nfs_folder(machine, '1.1.1.1', {'nfs' => {guestpath: '/mountpoint', hostpath: '/some/share'}})

      expect(comm.received_commands[0]).to match(/if \[ -d \/usbkey \] && \[ "\$\(zonename\)" == "global" \] ; then/)
      expect(comm.received_commands[0]).to match(/pfexec mkdir -p \/usbkey\/config.inc/)
      expect(comm.received_commands[0]).to match(/printf '1\.1\.1\.1:\/some\/share:\/mountpoint' | pfexec tee -a \/usbkey\/config.inc\/nfs_mounts/)
      expect(comm.received_commands[0]).to match(/fi/)
      expect(comm.received_commands[0]).to match(/pfexec mkdir -p \/mountpoint/)
      expect(comm.received_commands[0]).to match(/pfexec \/usr\/sbin\/mount -F nfs '1\.1\.1\.1:\/some\/share' '\/mountpoint'/)
    end
  end
end
