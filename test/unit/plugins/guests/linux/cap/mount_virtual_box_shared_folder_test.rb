require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::MountVirtualBoxSharedFolder" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
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
      hostpath: "/host/directory/path"
    }
  end
  let(:cap){ caps.get(:mount_virtualbox_shared_folder) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".mount_virtualbox_shared_folder" do

    before do
      allow(comm).to receive(:sudo).with(any_args)
      allow(comm).to receive(:execute).with(any_args)
    end

    it "generates the expected default mount command" do
      expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
      expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
      cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    it "automatically chown's the mounted directory on guest" do
      expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
      expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
      expect(comm).to receive(:sudo).with("chown #{mount_uid}:#{mount_gid} #{mount_guest_path}")
      cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
    end

    context "with owner user ID explicitly defined" do

      before do
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
      end

      context "with user ID provided as Integer" do
        let(:mount_owner){ 2000 }

        it "generates the expected mount command using mount_owner directly" do
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_owner},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
          expect(comm).to receive(:sudo).with("chown #{mount_owner}:#{mount_gid} #{mount_guest_path}")
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
        end
      end

      context "with user ID provided as String" do
        let(:mount_owner){ "2000" }

        it "generates the expected mount command using mount_owner directly" do
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_owner},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
          expect(comm).to receive(:sudo).with("chown #{mount_owner}:#{mount_gid} #{mount_guest_path}")
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
        end
      end

    end

    context "with owner group ID explicitly defined" do

      before do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
      end

      context "with owner group ID provided as Integer" do
        let(:mount_group){ 2000 }

        it "generates the expected mount command using mount_group directly" do
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{mount_group} #{mount_name} #{mount_guest_path}", anything)
          expect(comm).to receive(:sudo).with("chown #{mount_uid}:#{mount_group} #{mount_guest_path}")
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
        end
      end

      context "with owner group ID provided as String" do
        let(:mount_group){ "2000" }

        it "generates the expected mount command using mount_group directly" do
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{mount_group} #{mount_name} #{mount_guest_path}", anything)
          expect(comm).to receive(:sudo).with("chown #{mount_uid}:#{mount_group} #{mount_guest_path}")
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
        end
      end

    end

    context "with non-existent default owner group" do

      it "fetches the effective group ID of the user" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_raise(Vagrant::Errors::VirtualBoxMountFailed, {command: '', output: ''})
        expect(comm).to receive(:execute).with("id -g #{mount_owner}", anything).and_yield(:stdout, "1").and_return(0)
        cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end
    end

    context "with non-existent owner group" do

      it "raises an error" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_raise(Vagrant::Errors::VirtualBoxMountFailed, {command: '', output: ''})
        expect do
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
        end.to raise_error Vagrant::Errors::VirtualBoxMountFailed
      end
    end

    context "with read-only option defined" do

      it "does not chown mounted guest directory" do
        expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
        expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
        expect(comm).to receive(:sudo).with("mount -t vboxsf -o ro,uid=#{mount_uid},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
        expect(comm).not_to receive(:sudo).with("chown #{mount_uid}:#{mount_gid} #{mount_guest_path}")
        cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["ro"]))
      end
    end

    context "with upstart init" do

      it "emits mount event" do
        expect(comm).to receive(:sudo).with(/initctl emit/)
        cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options)
      end
    end

    context "with custom mount options" do

      let(:ui){ double(:ui) }
      before do
        allow(ui).to receive(:warn)
        allow(machine).to receive(:ui).and_return(ui)
      end

      context "with uid defined" do
        let(:options_uid){ '1234' }

        it "should only include uid defined within mount options" do
          expect(comm).not_to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
          expect(comm).to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{options_uid},gid=#{mount_gid} #{mount_name} #{mount_guest_path}", anything)
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["uid=#{options_uid}"]))
        end
      end

      context "with gid defined" do
        let(:options_gid){ '1234' }

        it "should only include gid defined within mount options" do
          expect(comm).to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
          expect(comm).not_to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{mount_gid}:")
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{mount_uid},gid=#{options_gid} #{mount_name} #{mount_guest_path}", anything)
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["gid=#{options_gid}"]))
        end
      end

      context "with uid and gid defined" do
        let(:options_gid){ '1234' }
        let(:options_uid){ '1234' }

        it "should only include uid and gid defined within mount options" do
          expect(comm).not_to receive(:execute).with("id -u #{mount_owner}", anything).and_yield(:stdout, mount_uid)
          expect(comm).not_to receive(:execute).with("getent group #{mount_group}", anything).and_yield(:stdout, "vagrant:x:#{options_gid}:")
          expect(comm).to receive(:sudo).with("mount -t vboxsf -o uid=#{options_uid},gid=#{options_gid} #{mount_name} #{mount_guest_path}", anything)
          cap.mount_virtualbox_shared_folder(machine, mount_name, mount_guest_path, folder_options.merge(mount_options: ["gid=#{options_gid}", "uid=#{options_uid}"]))
        end
      end
    end
  end

  describe ".unmount_virtualbox_shared_folder" do

    after { cap.unmount_virtualbox_shared_folder(machine, mount_guest_path, folder_options) }

    it "unmounts shared directory and deletes directory on guest" do
      expect(comm).to receive(:sudo).with("umount #{mount_guest_path}", anything).and_return(0)
      expect(comm).to receive(:sudo).with("rmdir #{mount_guest_path}", anything)
    end

    it "does not delete guest directory if unmount fails" do
      expect(comm).to receive(:sudo).with("umount #{mount_guest_path}", anything).and_return(1)
      expect(comm).not_to receive(:sudo).with("rmdir #{mount_guest_path}", anything)
    end
  end
end
