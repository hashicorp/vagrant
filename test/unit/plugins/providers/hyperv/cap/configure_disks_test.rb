require_relative "../../../../base"
require Vagrant.source_root.join("plugins/providers/hyperv/cap/configure_disks")

describe VagrantPlugins::HyperV::Cap::ConfigureDisks do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:driver) { double("driver") }

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m).to receive(:state).and_return(state)
    end
  end

  let(:state) do
    double(:state)
  end

  let(:defined_disks) { [double("disk", name: "vagrant_primary", size: "5GB", primary: true, type: :disk),
                         double("disk", name: "disk-0", size: "5GB", primary: false, type: :disk),
                         double("disk", name: "disk-1", size: "5GB", primary: false, type: :disk),
                         double("disk", name: "disk-2", size: "5GB", primary: false, type: :disk)] }

  let(:subject) { described_class }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
  end

  context "#configure_disks" do
    it "configures disks and returns the disks defined" do
    end

    describe "with no disks to configure" do
      it "returns empty hash if no disks to configure" do
      end
    end
  end

  context "#get_current_disk" do
    it "gets primary disk uuid if disk to configure is primary" do
    end

    it "finds the disk to configure" do
    end

    it "returns nil if disk is not found" do
    end
  end

  context "#handle_configure_disk" do
    describe "when creating a new disk" do
      it "creates a new disk if it doesn't yet exist" do
      end
    end

    describe "when a disk needs to be resized" do
      it "resizes a disk" do
      end
    end

    describe "if no additional disk configuration is required" do
      it "does nothing if all disks are properly configured" do
      end
    end
  end

  context "#compare_disk_size" do
  end

  context "#create_disk" do
    it "creates a disk and attaches it to a guest" do
    end
  end

  context "#resize_disk" do
  end
end
