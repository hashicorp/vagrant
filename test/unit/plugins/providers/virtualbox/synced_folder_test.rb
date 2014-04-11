require "vagrant"
require Vagrant.source_root.join("test/unit/base")

require Vagrant.source_root.join("plugins/providers/virtualbox/config")
require Vagrant.source_root.join("plugins/providers/virtualbox/synced_folder")

describe VagrantPlugins::ProviderVirtualBox::SyncedFolder do
  let(:machine) do
    double("machine").tap do |m|
      m.stub(provider_config: VagrantPlugins::ProviderVirtualBox::Config.new)
      m.stub(provider_name: :virtualbox)
    end
  end

  subject { described_class.new }

  before do
    machine.provider_config.finalize!
  end

  describe "usable" do
    it "should be with virtualbox provider" do
      machine.stub(provider_name: :virtualbox)
      expect(subject).to be_usable(machine)
    end

    it "should not be with another provider" do
      machine.stub(provider_name: :vmware_fusion)
      expect(subject).not_to be_usable(machine)
    end

    it "should not be usable if not functional vboxsf" do
      machine.provider_config.functional_vboxsf = false
      expect(subject).to_not be_usable(machine)
    end
  end

  describe "prepare" do
    let(:driver) { double("driver") }

    before do
      machine.stub(driver: driver)
    end

    it "should share the folders" do
      pending
    end
  end
end
