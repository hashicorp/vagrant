require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::PersistMountSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:cap){ caps.get(:persist_mount_shared_folder) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".persist_mount_shared_folder" do
    let(:options_gid){ '1234' }
    let(:options_uid){ '1234' }

    let (:fstab_folders) { [
      ["test1", {:guestpath=>"/test1", :hostpath=>"/my/host/path", :disabled=>false, :__vagrantfile=>true, :owner=>"vagrant", :group=>"vagrant", :mount_options=>["uid=1234", "gid=1234"] }],
      ["vagrant", {:guestpath=>"/vagrant", :hostpath=>"/my/host/vagrant", :disabled=>false, :__vagrantfile=>true, :owner=>"vagrant", :group=>"vagrant", :mount_options=>["uid=1234", "gid=1234"] }]
    ]}

    let(:ui){ double(:ui) }

    before do
      allow(comm).to receive(:sudo).with(any_args)
      allow(ui).to receive(:warn)
      allow(machine).to receive(:ui).and_return(ui)
    end

    it "inserts folders into /etc/fstab" do
      expected_entry_vagrant = "vagrant /vagrant vboxsf uid=1234,gid=1234,nofail 0 0"
      expected_entry_test = "test1 /test1 vboxsf uid=1234,gid=1234,nofail 0 0"
      expect(cap).to receive(:remove_vagrant_managed_fstab)
      expect(comm).to receive(:sudo).with(/#{expected_entry_test}\n#{expected_entry_vagrant}/)
      cap.persist_mount_shared_folder(machine, fstab_folders, "vboxsf")
    end

    it "does not insert an empty set of folders" do
      expect(cap).to receive(:remove_vagrant_managed_fstab)
      cap.persist_mount_shared_folder(machine, [], "type")
    end
  end
end
