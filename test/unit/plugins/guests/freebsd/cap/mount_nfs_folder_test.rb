require_relative "../../../../base"

describe "VagrantPlugins::GuestFreeBSD::Cap::MountNFSFolder" do
  let(:described_class) do
    VagrantPlugins::GuestFreeBSD::Plugin
      .components
      .guest_capabilities[:freebsd]
      .get(:mount_nfs_folder)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_nfs_folder" do
    let(:ip) { "1.2.3.4" }

    it "mounts the folder" do
      folders = {
        "/vagrant-nfs" => {
          type: :nfs,
          guestpath: "/guest",
          hostpath: "/host",
        }
      }
      described_class.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[0]).to match(/mkdir -p '\/guest'/)
      expect(comm.received_commands[0]).to match(/'1.2.3.4:\/host' '\/guest'/)
    end

    it "mounts with options" do
      folders = {
        "/vagrant-nfs" => {
          type: :nfs,
          guestpath: "/guest",
          hostpath: "/host",
          nfs_version: 2,
        }
      }
      described_class.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[0]).to match(/mount -t nfs -o nfsv2/)
    end
  end
end
