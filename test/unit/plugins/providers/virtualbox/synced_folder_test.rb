require "vagrant"
require Vagrant.source_root.join("test/unit/base")

require Vagrant.source_root.join("plugins/providers/virtualbox/config")
require Vagrant.source_root.join("plugins/providers/virtualbox/synced_folder")

describe VagrantPlugins::ProviderVirtualBox::SyncedFolder do
  include_context "unit"
  let(:machine) do
    double("machine").tap do |m|
      allow(m).to receive(:provider_config).and_return(VagrantPlugins::ProviderVirtualBox::Config.new)
      allow(m).to receive(:provider_name).and_return(:virtualbox)
    end
  end

  subject { described_class.new }

  before do
    machine.provider_config.finalize!
  end

  describe "usable" do
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

  describe "prepare" do
    let(:driver) { double("driver") }
    let(:provider) { double("driver", driver: driver) }
    let(:folders) { {"/folder"=>
                      {:SharedFoldersEnableSymlinksCreate=>true,
                       :guestpath=>"/folder",
                       :hostpath=>"/Users/brian/vagrant-folder",
                       :disabled=>false,
                       :__vagrantfile=>true}} }

    let(:folders_disabled) { {"/folder"=>
                                {:SharedFoldersEnableSymlinksCreate=>false,
                                 :guestpath=>"/folder",
                                 :hostpath=>"/Users/brian/vagrant-folder",
                                 :disabled=>false,
                                 :__vagrantfile=>true}} }

    let(:folders_nosymvar) { {"/folder"=>
                                {:guestpath=>"/folder",
                                 :hostpath=>"/Users/brian/vagrant-folder",
                                 :disabled=>false,
                                 :__vagrantfile=>true}} }

    before do
      allow(machine).to receive(:provider).and_return(provider)
    end

    it "should prepare and share the folders" do
      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :SharedFoldersEnableSymlinksCreate=>true}])
      subject.prepare(machine, folders, nil)
    end

    it "should prepare and share the folders without symlinks enabled" do
      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :SharedFoldersEnableSymlinksCreate=>false}])
      subject.prepare(machine, folders_disabled, nil)
    end

    it "should prepare and share the folders without symlinks enabled with env var set" do
      stub_env('VAGRANT_DISABLE_VBOXSYMLINKCREATE'=>'1')

      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :SharedFoldersEnableSymlinksCreate=>false}])
      subject.prepare(machine, folders_nosymvar, nil)
    end

    it "should prepare and share the folders and override symlink setting" do
      stub_env('VAGRANT_DISABLE_VBOXSYMLINKCREATE'=>'1')

      expect(driver).to receive(:share_folders).with([{:name=>"folder", :hostpath=>"/Users/brian/vagrant-folder", :transient=>false, :SharedFoldersEnableSymlinksCreate=>true}])
      subject.prepare(machine, folders, nil)
    end
  end

  describe "os_friendly_id" do
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
end
