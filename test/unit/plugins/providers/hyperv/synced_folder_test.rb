require "vagrant"

require Vagrant.source_root.join("test/unit/base")
require Vagrant.source_root.join("plugins/providers/hyperv/config")
require Vagrant.source_root.join("plugins/providers/hyperv/errors")
require Vagrant.source_root.join("plugins/providers/hyperv/sync_helper")
require Vagrant.source_root.join("plugins/providers/hyperv/synced_folder")

describe VagrantPlugins::HyperV::SyncedFolder do
  include_context "unit"
  let(:guest) { double("guest") }
  let(:ui) { double("ui") }
  let(:ssh_info) { {username: "vagrant"} }
  let(:provider) { double("provider") }
  let(:machine) do
    double("machine").tap do |m|
      allow(m).to receive(:provider_config).and_return(VagrantPlugins::HyperV::Config.new)
      allow(m).to receive(:provider_name).and_return(:hyperv)
      allow(m).to receive(:guest).and_return(guest)
      allow(m).to receive(:provider).and_return(provider)
      allow(m).to receive(:ssh_info).and_return(ssh_info)
      allow(m).to receive(:ui).and_return(ui)
    end
  end
  let(:helper_class) { VagrantPlugins::HyperV::SyncHelper }

  subject { described_class.new }

  before do
    I18n.load_path << Vagrant.source_root.join("templates/locales/providers_hyperv.yml")
    I18n.reload!
    machine.provider_config.finalize!
  end

  describe "#usable?" do
    it "should be with hyperv provider" do
      allow(machine).to receive(:provider_name).and_return(:hyperv)
      expect(subject).to be_usable(machine)
    end

    it "should not be with another provider" do
      allow(machine).to receive(:provider_name).and_return(:vmware_fusion)
      expect(subject).not_to be_usable(machine)
    end
  end

  describe "#share_folders" do
    let(:folders) do
      { 'folder1' => { hostpath: 'C:\vagrant', guestpath: '/vagrant' },
        'folder2' => { hostpath: 'C:\vagrant2', guestpath: '/vagrant2' },
        'ignored' => { hostpath: 'C:\vagrant3' } }
    end

    before do
      allow(subject).to receive(:configure_hv_daemons).and_return(true)
      allow(ui).to receive(:output)
      allow(ui).to receive(:info)
      allow(ui).to receive(:detail)
      allow(helper_class).to receive(:sync_single).
        with(machine, ssh_info,
             hostpath: 'C:\vagrant',
             guestpath: "/vagrant")
      allow(helper_class).to receive(:sync_single).
        with(machine, ssh_info,
             hostpath: 'C:\vagrant2',
             guestpath: "/vagrant2")
    end

    it "should sync folders" do
      subject.send(:enable, machine, folders, {})
    end
  end

  describe "#configure_hv_daemons" do
    before do
      allow(ui).to receive(:info)
      allow(ui).to receive(:warn)
    end

    it "runs guest which does not support capability :hyperv_daemons_running" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(false)
      expect(subject.send(:configure_hv_daemons, machine)).to be_falsy
    end

    it "runs guest which has all hyperv daemons running" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(true)
      expect(subject.send(:configure_hv_daemons, machine)).to be_truthy
    end

    it "runs guest which has hyperv daemons installed but not running" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(false)
      allow(guest).to receive(:capability).with(:hyperv_daemons_installed).and_return(true)
      allow(guest).to receive(:capability?).with(:hyperv_daemons_activate).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_activate).and_return(true)
      expect(subject.send(:configure_hv_daemons, machine)).to be_truthy
    end

    it "runs guest which has hyperv daemons installed but cannot activate" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(false)
      allow(guest).to receive(:capability).with(:hyperv_daemons_installed).and_return(true)
      allow(guest).to receive(:capability?).with(:hyperv_daemons_activate).and_return(false)
      expect(subject.send(:configure_hv_daemons, machine)).to be_falsy
    end

    it "runs guest which has hyperv daemons installed but activate failed" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(false)
      allow(guest).to receive(:capability).with(:hyperv_daemons_installed).and_return(true)
      allow(guest).to receive(:capability?).with(:hyperv_daemons_activate).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_activate).and_return(false)
      expect(subject.send(:configure_hv_daemons, machine)).to be_falsy
    end

    it "runs guest which has no hyperv daemons and unable to install" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(false)
      allow(guest).to receive(:capability).with(:hyperv_daemons_installed).and_return(false)
      allow(guest).to receive(:capability?).with(:hyperv_daemons_install).and_return(false)
      expect(subject.send(:configure_hv_daemons, machine)).to be_falsy
    end

    it "runs guest which has hyperv daemons newly installed but failed to activate" do
      allow(guest).to receive(:capability?).with(:hyperv_daemons_running).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_running).and_return(false)
      allow(guest).to receive(:capability).with(:hyperv_daemons_installed).and_return(false)
      allow(guest).to receive(:capability?).with(:hyperv_daemons_install).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_install).and_return(true)
      allow(guest).to receive(:capability?).with(:hyperv_daemons_activate).and_return(true)
      allow(guest).to receive(:capability).with(:hyperv_daemons_activate).and_return(false)
      expect(subject.send(:configure_hv_daemons, machine)).to be_falsy
    end
  end
end
