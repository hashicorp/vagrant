require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::MountSMBSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine", env: env) }
  let(:env) { double("env", host: host) }
  let(:host) { double("host") }
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
    allow(host).to receive(:capability?).and_return(false)
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

    it "removes the credentials file before completion" do
      expect(comm).to receive(:sudo).with(/rm.+smb_creds_.+/)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "sends upstart notification after mount" do
      expect(comm).to receive(:sudo).with(/emit/)
      cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    context "with custom mount options" do
      let(:folder_options) do
        {
          owner: mount_owner,
          group: mount_group,
          smb_host: "localhost",
          smb_username: "user",
          smb_password: "pass",
          mount_options: ["ro", "sec=custom"]
        }
      end

      it "adds given mount options to command" do
        expect(comm).to receive(:sudo).with(/ro/, any_args)
        cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end

      it "replaces defined options" do
        expect(comm).to receive(:sudo).with(/sec=custom/, any_args)
        cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end

      it "does not include replaced options" do
        expect(comm).not_to receive(:sudo).with(/sec=ntlm/, any_args)
        cap.mount_smb_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end
    end
  end

  describe ".merge_mount_options" do
    let(:base){ ["opt1", "opt2=on", "opt3", "opt4,opt5=off"] }
    let(:override){ ["opt8", "opt4=on,opt6,opt7=true"] }

    context "with no override" do
      it "should split options into individual options" do
        result = cap.merge_mount_options(base, [])
        expect(result.size).to eq(5)
      end
    end

    context "with overrides" do
      it "should merge all options" do
        result = cap.merge_mount_options(base, override)
        expect(result.size).to eq(8)
      end

      it "should override options defined in base" do
        result = cap.merge_mount_options(base, override)
        expect(result).to include("opt4=on")
      end
    end
  end
end
