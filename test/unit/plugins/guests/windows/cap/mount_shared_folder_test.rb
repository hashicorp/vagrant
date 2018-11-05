require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/windows/cap/mount_shared_folder")

describe "VagrantPlugins::GuestWindows::Cap::MountSharedFolder" do

  let(:machine) { double("machine") }
  let(:communicator) { double(:execute) }
  let(:config) { double("config") }
  let(:vm) { double("vm") }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(communicator).to receive(:execute)
    allow(machine).to receive(:config).and_return(config)
    allow(config).to receive(:vm).and_return(vm)
    allow(vm).to receive(:communicator).and_return(:winrm)
  end

  describe "virtualbox" do

    let(:described_class) do
      VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:mount_virtualbox_shared_folder)
    end

    describe ".mount_shared_folder" do
      it "should call mount_volume script with correct args" do
        expect(Vagrant::Util::TemplateRenderer).to receive(:render).with(
          /.+scripts\/mount_volume.ps1/, options: {
              mount_point: "guestpath",
              share_name: "name",
              vm_provider_unc_path: "\\\\vboxsvr\\name",
            })
        described_class.mount_virtualbox_shared_folder(machine, 'name', 'guestpath', {})
      end

      it "should replace invalid Windows share chars" do
        expect(Vagrant::Util::TemplateRenderer).to receive(:render).with(
          kind_of(String), options: {
              mount_point: kind_of(String),
              share_name: "invalid-windows_sharename",
              vm_provider_unc_path: "\\\\vboxsvr\\invalid-windows_sharename",
            })
        described_class.mount_virtualbox_shared_folder(machine, "/invalid-windows/sharename", "guestpath", {})
      end
    end
  end

  describe "vmware" do

    let(:described_class) do
      VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:mount_vmware_shared_folder)
    end

    describe ".mount_shared_folder" do
      it "should call mount_volume script with correct args" do
        expect(Vagrant::Util::TemplateRenderer).to receive(:render).with(
          /.+scripts\/mount_volume.ps1/, options: {
              mount_point: "guestpath",
              share_name: "name",
              vm_provider_unc_path: "\\\\vmware-host\\Shared Folders\\name",
            })
        described_class.mount_vmware_shared_folder(machine, 'name', 'guestpath', {})
      end
    end
  end

  describe "parallels" do

    let(:described_class) do
      VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:mount_parallels_shared_folder)
    end

    describe ".mount_shared_folder" do
      it "should call mount_volume script with correct args" do
        expect(Vagrant::Util::TemplateRenderer).to receive(:render).with(
          /.+scripts\/mount_volume.ps1/, options: {
              mount_point: "guestpath",
              share_name: "name",
              vm_provider_unc_path: "\\\\psf\\name",
            })
        described_class.mount_parallels_shared_folder(machine, 'name', 'guestpath', {})
      end
    end
  end

  describe "smb" do

    let(:described_class) do
      VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:mount_smb_shared_folder)
    end

    describe ".mount_shared_folder" do
      it "should call mount_volume script with correct args" do
        expect(Vagrant::Util::TemplateRenderer).to receive(:render).with(
          /.+scripts\/mount_volume.ps1/, options: {
              mount_point: "guestpath",
              share_name: "name",
              vm_provider_unc_path: "\\\\host\\name",
            })
        expect(machine.communicate).to receive(:execute).with("cmdkey /add:host /user:user /pass:\"pass\"", {:shell=>:powershell, :elevated=>true})
        described_class.mount_smb_shared_folder(machine, 'name', 'guestpath', {:smb_username => "user", :smb_password => "pass", :smb_host => "host"})
      end
    end
  end

  describe "virtualbox-ssh" do

    let(:described_class) do
      VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:mount_virtualbox_shared_folder)
    end

    before do
      allow(vm).to receive(:communicator).and_return(:ssh)
    end

    describe ".mount_shared_folder" do
      it "should call mount_volume script via ssh" do
        expect(communicator).to receive(:execute).with(/powershell/, shell: "sh")
        described_class.mount_virtualbox_shared_folder(machine, 'name', 'guestpath', {})
      end
    end
  end

end
