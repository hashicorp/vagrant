require_relative "../../../../base"

describe "VagrantPlugins::GuestOmniOS::Cap:RSync" do
  let(:caps) do
    VagrantPlugins::GuestOmniOS::Plugin
      .components
      .guest_capabilities[:omnios]
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

    it "mounts with options"
  end
end
