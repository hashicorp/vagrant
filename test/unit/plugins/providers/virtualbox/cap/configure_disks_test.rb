require_relative "../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/cap/configure_disks")

describe VagrantPlugins::ProviderVirtualBox::Cap::ConfigureDisks do
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

  let(:vm_info) { {"SATA Controller-ImageUUID-0-0" => "12345",
                   "SATA Controller-ImageUUID-1-0" => "67890"} }

  let(:defined_disks) { [double("disk-0", name: "disk-0", size: "5GB", type: :disk),
                        double("disk-1", name: "disk-1", size: "5GB", type: :disk),
                        double("disk-2", name: "disk-2", size: "5GB", type: :disk),
                        double("disk-3", name: "disk-3", size: "5GB", type: :disk)] }

  let(:subject) { described_class }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
    allow(driver).to receive(:show_vm_info).and_return(vm_info)
  end

  context "#configure_disks" do
    let(:dsk_data) { {uuid: "1234", name: "disk"} }
    it "configures disks and returns the disks defined" do
      allow(driver).to receive(:list_hdds).and_return([])

      expect(subject).to receive(:handle_configure_disk).exactly(4).and_return(dsk_data)
      subject.configure_disks(machine, defined_disks)
    end

    describe "with no disks to configure" do
      let(:defined_disks) { {} }
      it "returns empty hash if no disks to configure" do
        expect(subject.configure_disks(machine, defined_disks)).to eq({})
      end
    end

    describe "with over the disk limit for a given device" do
      let(:defined_disks) { (1..31).each { |i| double("disk-#{i}") }.to_a }

      it "raises an exception if the disks defined exceed the limit for a SATA Controller" do
        expect{subject.configure_disks(machine, defined_disks)}.
          to raise_error(Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit)
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
  end

  context "#compare_disk_size" do
    it "shows a warning if user attempts to shrink size" do
    end

    it "returns true if requested size is bigger than current size" do
    end
  end

  context "#create_disk" do
    it "creates a disk and attaches it to a guest" do
    end
  end

  context "#get_next_port" do
    it "determines the next available port to use" do
    end

    it "returns empty string if no usable port is available" do
    end
  end

  context "#resize_disk" do
    describe "when a disk is vmdk format" do
      it "converts the disk to vdi, resizes it, and converts back to vmdk" do
      end
    end

    it "resizes the disk" do
    end
  end

  context "#vmdk_to_vdi" do
    it "converts a disk from vmdk to vdi" do
    end
  end

  context "#vdi_to_vmdk" do
    it "converts a disk from vdi to vmdk" do
    end
  end
end
