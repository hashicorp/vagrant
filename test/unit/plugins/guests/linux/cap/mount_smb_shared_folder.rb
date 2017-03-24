require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::MountSMBSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
  let(:guest) { double("guest") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:mount_owner){ "vagrant" }
  let(:mount_group){ "vagrant" }
  let(:mount_uid){ "1000" }
  let(:mount_gid){ "1000" }
  let(:mount_name){ "vagrant" }
  let(:mount_guest_path){ "/vagrant" }
  let(:folder_options) do
    {
      owner: mount_owner,
      group: mount_group,
      smb_host: "localhost",
      smb_username: "user",
      smb_password: "pass"
    }
  end
  let(:cap){ caps.get(:mount_smb_shared_folder) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_smb_shared_folder" do
    before do
      allow(comm).to receive(:sudo).with(any_args).and_return(0)
      allow(comm).to receive(:execute).with(any_args)
      allow(machine).to receive(:guest).and_return(guest)
      allow(guest).to receive(:capability).with(:shell_expand_guest_path, mount_guest_path).and_return(mount_guest_path)
    end

    it "generates the expected default mount command" do
      expect(comm).to receive(:sudo).with(/mount -t cifs/, anything).and_return(0)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "creates directory on guest machine" do
      expect(comm).to receive(:sudo).with("mkdir -p #{mount_guest_path}")
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "writes username into guest credentials file" do
      expect(comm).to receive(:sudo).with(/smb_creds.*username=#{folder_options[:smb_username]}/m)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "writes password into guest credentials file" do
      expect(comm).to receive(:sudo).with(/smb_creds.*password=#{folder_options[:smb_password]}/m)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "sends upstart notification after mount" do
      expect(comm).to receive(:sudo).with(/emit/)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end
  end
end
