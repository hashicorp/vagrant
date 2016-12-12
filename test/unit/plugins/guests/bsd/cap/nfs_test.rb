require_relative "../../../../base"

describe "VagrantPlugins::GuestBSD::Cap::NFS" do
  let(:caps) do
    VagrantPlugins::GuestBSD::Plugin
      .components
      .guest_capabilities[:bsd]
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

    it "mounts the folder" do
      folders = {
        "/vagrant-nfs" => {
          guestpath: "/guest",
          hostpath: "/host",
        }
      }
      cap.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[0]).to match(/mkdir -p \/guest/)
      expect(comm.received_commands[1]).to match(/mount -t nfs/)
      expect(comm.received_commands[1]).to match(/1.2.3.4:\/host \/guest/)
    end

    it "mounts with options" do
      folders = {
        "/vagrant-nfs" => {
          guestpath: "/guest",
          hostpath: "/host",
          nfs_version: 2,
          nfs_udp: true,
          mount_options: ["banana"]
        }
      }
      cap.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[1]).to match(/mount -t nfs -o 'nfsv2,mntudp,banana'/)
    end

    it "escapes host and guest paths" do
      folders = {
        "/vagrant-nfs" => {
          guestpath: "/guest with spaces",
          hostpath: "/host's",
        }
      }
      cap.mount_nfs_folder(machine, ip, folders)

      expect(comm.received_commands[1]).to match(/host\\\'s/)
      expect(comm.received_commands[1]).to match(/guest\\\ with\\\ spaces/)
    end
  end
end
