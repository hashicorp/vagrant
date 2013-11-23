require "vagrant"
require Vagrant.source_root.join("test/unit/base")

require Vagrant.source_root.join("plugins/providers/virtualbox/synced_folder")

# TODO(mitchellh): tag with v2
describe VagrantPlugins::ProviderVirtualBox::SyncedFolder do
  let(:machine) do
    double("machine").tap do |m|
    end
  end

  subject { described_class.new }

  describe "usable" do
    it "should be with virtualbox provider" do
      machine.stub(provider_name: :virtualbox)
      subject.should be_usable(machine)
    end

    it "should not be with another provider" do
      machine.stub(provider_name: :vmware_fusion)
      subject.should_not be_usable(machine)
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
