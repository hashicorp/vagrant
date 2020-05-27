require "vagrant"
require Vagrant.source_root.join("test/unit/base")

require Vagrant.source_root.join("plugins/providers/virtualbox/config")
require Vagrant.source_root.join("plugins/providers/virtualbox/synced_folder")

describe VagrantPlugins::ProviderVirtualBox::SyncedFolder do
  include_context "unit"

  let(:vm_config) do
    double("vm_config").tap do |vm_config|
      allow(vm_config).to receive(:allow_fstab_modification).and_return(true)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      allow(top_config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:machine) do
    double("machine").tap do |m|
      allow(m).to receive(:provider_config).and_return(VagrantPlugins::ProviderVirtualBox::Config.new)
      allow(m).to receive(:provider_name).and_return(:virtualbox)
      allow(m).to receive(:config).and_return(machine_config)
    end
  end

  let(:folders) { {"/folder"=>
    {:SharedFoldersEnableSymlinksCreate=>true,
     :guestpath=>"/folder",
     :hostpath=>"/Users/brian/vagrant-folder",
     :automount=>false,
     :disabled=>false,
     :__vagrantfile=>true}} }

  subject { described_class.new }

  before do
    machine.provider_config.finalize!
  end

  describe "#usable?" do
    it "should be with virtualbox provider" do
      allow(machine).to receive(:provider_name).and_return(:virtualbox)
      expect(subject).to be_usable(machine)
    end

    it "should not be with another provider" do
      allow(machine).to receive(:provider_name).and_return(:vmware_fusion)
      expect(subject).not_to be_usable(machine)
    end

    it "should not be usable if not functional vboxsf" do
      machine.provider_config.functional_vboxsf = false
      expect(subject).to_not be_usable(machine)
    end
  end

  describe "#enable" do
    let(:ui){ double(:ui) }
    let(:guest) { double("guest") }

    let(:no_guestpath_folder) { {"/no_guestpath_folder"=>
      {:SharedFoldersEnableSymlinksCreate=>false,
       :guestpath=>nil,
       :hostpath=>"/Users/brian/vagrant-folder",
       :automount=>false,
       :disabled=>true,
       :__vagrantfile=>true}} }

    before do
      allow(subject).to receive(:share_folders).and_return(true)
      allow(ui).to receive(:detail).with(any_args)
      allow(ui).to receive(:output).with(any_args)
      allow(machine).to receive(:ui).and_return(ui)
      allow(machine).to receive(:ssh_info).and_return({:username => "test"})
      allow(machine).to receive(:guest).and_return(guest)
    end

    it "should mount and persist all folders with a guest path" do
      expect(guest).to receive(:capability).with(:mount_virtualbox_shared_folder, "folder", any_args)
      expect(guest).not_to receive(:capability).with(:mount_virtualbox_shared_folder, "no_guestpath_folder", any_args)
      expect(guest).to receive(:capability?).with(:persist_mount_shared_folder).and_return(true)
      expect(guest).to receive(:capability).with(:persist_mount_shared_folder, any_args)
      test_folders = folders.merge(no_guestpath_folder)
      subject.enable(machine, test_folders, nil)
    end

    context "fstab modification disabled" do
      before do
       allow(vm_config).to receive(:allow_fstab_modification).and_return(false)
      end

      it "should not persist folders" do
        expect(guest).to receive(:capability).with(:mount_virtualbox_shared_folder, "folder", any_args)
        expect(guest).not_to receive(:capability).with(:mount_virtualbox_shared_folder, "no_guestpath_folder", any_args)
        expect(guest).to receive(:capability?).with(:persist_mount_shared_folder).and_return(true)
        expect(guest).to receive(:capability).with(:persist_mount_shared_folder, [], "vboxsf")
        test_folders = folders.merge(no_guestpath_folder)
        subject.enable(machine, test_folders, nil)
      end
    end
  end

  describe "#prepare" do
    let(:driver) { double("driver") }
    let(:provider) { double("driver", driver: driver) }

    let(:folders_disabled) { {"/folder"=>
                                {:SharedFoldersEnableSymlinksCreate=>false,
                                 :guestpath=>"/folder",
                                 :hostpath=>"/Users/brian/vagrant-folder",
                                 :automount=>false,
                                 :disabled=>false,
                                 :__vagrantfile=>true}} }


    let(:folders_automount) { {"/folder"=>
                                {:SharedFoldersEnableSymlinksCreate=>true,
                                 :guestpath=>"/folder",
                                 :hostpath=>"/Users/brian/vagrant-folder",
                                 :disabled=>false,
                                 :automount=>true,
                                 :__vagrantfile=>true}} }

    let(:folders_nosymvar) { {"/folder"=>
                                {:guestpath=>"/folder",
                                 :hostpath=>"/Users/brian/vagrant-folder",
                                 :automount=>false,
                                 :disabled=>false,
                                 :__vagrantfile=>true}} }

    before do
      allow(machine).to receive(:provider).and_return(provider)
      allow(machine).to receive(:env)
      allow(subject).to receive(:display_symlink_create_warning)
    end

    it "should prepare and share the folders" do
      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :automount=>false, :SharedFoldersEnableSymlinksCreate=>true}])
      subject.prepare(machine, folders, nil)
    end

    it "should prepare and share the folders without symlinks enabled" do
      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :automount=>false, :SharedFoldersEnableSymlinksCreate=>false}])
      subject.prepare(machine, folders_disabled, nil)
    end

    it "should prepare and share the folders without symlinks enabled with env var set" do
      stub_env('VAGRANT_DISABLE_VBOXSYMLINKCREATE'=>'1')

      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :automount=>false, :SharedFoldersEnableSymlinksCreate=>false}])
      subject.prepare(machine, folders_nosymvar, nil)
    end

    it "should prepare and share the folders and override symlink setting" do
      stub_env('VAGRANT_DISABLE_VBOXSYMLINKCREATE'=>'1')

      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :automount=>false, :SharedFoldersEnableSymlinksCreate=>true}])
      subject.prepare(machine, folders, nil)
    end

    it "should prepare and share the folders with automount enabled" do
      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :SharedFoldersEnableSymlinksCreate=>true, :automount=>true}])
      subject.prepare(machine, folders_automount, nil)
    end
  end

  describe "#os_friendly_id" do
    it "should not replace normal chars" do
      expect(subject.send(:os_friendly_id, 'perfectly_valid0_name')).to eq('perfectly_valid0_name')
    end

    it "should replace spaces" do
      expect(subject.send(:os_friendly_id, 'Program Files')).to eq('Program_Files')
    end

    it "should replace leading underscore" do
      expect(subject.send(:os_friendly_id, '_vagrant')).to eq('vagrant')
    end

    it "should replace slash" do
      expect(subject.send(:os_friendly_id, 'va/grant')).to eq('va_grant')
    end

    it "should replace leading underscore and slash" do
      expect(subject.send(:os_friendly_id, '/vagrant')).to eq('vagrant')
    end

    it "should replace backslash" do
      expect(subject.send(:os_friendly_id, 'foo\\bar')).to eq('foo_bar')
    end
  end

  describe "#share_folders" do
    let(:folders){ {'folder1' => {hostpath: '/vagrant', transient: true},
      'folder2' => {hostpath: '/vagrant2', transient: false}} }
    let(:symlink_create_disable){ nil }
    let(:driver){ double("driver") }

    before do
      allow(subject).to receive(:display_symlink_create_warning)
      allow(machine).to receive(:env)
      allow(subject).to receive(:driver).and_return(driver)
      allow(driver).to receive(:share_folders)
      allow(ENV).to receive(:[]).with("VAGRANT_DISABLE_VBOXSYMLINKCREATE").and_return(symlink_create_disable)
    end

    it "should only add transient folder" do
      expect(driver).to receive(:share_folders).with(any_args) do |defs|
        expect(defs.size).to eq(1)
      end
      subject.send(:share_folders, machine, folders, true)
    end

    it "should display symlink create warning" do
      expect(subject).to receive(:display_symlink_create_warning)
      subject.send(:share_folders, machine, folders, true)
    end

    context "with create symlink globally disabled" do
      let(:symlink_create_disable){ "1" }

      it "should not enable option within definitions" do
        expect(driver).to receive(:share_folders).with(any_args) do |defs|
          expect(defs.first[:SharedFoldersEnableSymlinksCreate]).to be(false)
        end
        subject.send(:share_folders, machine, folders, true)
      end

      it "should not display symlink warning" do
        expect(subject).not_to receive(:display_symlink_create_warning)
        subject.send(:share_folders, machine, folders, true)
      end
    end
  end

  describe "#display_symlink_create_warning" do
    let(:env){ double("env", ui: double("ui"), data_dir: double("data_dir")) }
    let(:gate_file){ double("gate") }

    before{ allow(gate_file).to receive(:to_path).and_return("PATH") }
    after{ subject.send(:display_symlink_create_warning, env) }

    context "gate file does not exist" do
      before do
        allow(env.data_dir).to receive(:join).and_return(gate_file)
        allow(gate_file).to receive(:exist?).and_return(false)
        allow(FileUtils).to receive(:touch)
        allow(env.ui).to receive(:warn)
      end

      it "should create file" do
        expect(FileUtils).to receive(:touch).with("PATH")
      end

      it "should output warning to user" do
        expect(env.ui).to receive(:warn)
      end
    end

    context "gate file does exist" do
      before do
        allow(env.data_dir).to receive(:join).and_return(gate_file)
        allow(gate_file).to receive(:exist?).and_return(true)
        allow(FileUtils).to receive(:touch)
        allow(env.ui).to receive(:warn)
      end

      it "should not create/update file" do
        expect(FileUtils).not_to receive(:touch).with("PATH")
      end

      it "should not output warning to user" do
        expect(env.ui).not_to receive(:warn)
      end
    end
  end
end
