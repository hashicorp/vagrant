require_relative "../../../../base"

describe "VagrantPlugins::GuestFreeBSD::Cap::MountNFSFolder" do
  let(:caps) do
    VagrantPlugins::GuestFreeBSD::Plugin
      .components
      .guest_capabilities[:freebsd]
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
    let(:cap) { caps.get(:mount_nfs_folder) }

    let(:ip) { "1.2.3.4" }

    let(:hostpath) { "/host" }
    let(:guestpath) { "/guest" }

    before do
      allow(machine).to receive(:guest).and_return(
        double("capability", capability: guestpath)
      )
    end

    it "mounts the folder" do
      folders = {
        "/vagrant-nfs" => {
          type: :nfs,
          guestpath: "/guest",
          hostpath: "/host",
        }
      }
      cap.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[0]).to match(/mkdir -p '#{guestpath}'/)
      expect(comm.received_commands[0]).to match(/'1.2.3.4:#{hostpath}' '#{guestpath}'/)
    end

    it "mounts with options" do
      folders = {
        "/vagrant-nfs" => {
          type: :nfs,
          guestpath: "/guest",
          hostpath: "/host",
          nfs_version: 2,
          nfs_udp: true,
        }
      }
      cap.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[0]).to match(/mount -t nfs -o nfsv2,udp/)
    end

    it "emits an event" do
      folders = {
        "/vagrant-nfs" => {
          type: :nfs,
          guestpath: "/guest",
          hostpath: "/host",
        }
      }
      cap.mount_nfs_folder(machine, ip, folders)
    end
  end
end
