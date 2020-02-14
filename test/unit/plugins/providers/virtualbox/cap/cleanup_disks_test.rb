require_relative "../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/cap/cleanup_disks")

describe VagrantPlugins::ProviderVirtualBox::Cap::CleanupDisks do
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

  let(:subject) { described_class }

  let(:disk_meta_file) { {disk: [], floppy: [], dvd: []} }
  let(:defined_disks) { {} }

  let(:vm_info) { {"SATA Controller-ImageUUID-0-0" => "12345",
                   "SATA Controller-ImageUUID-1-0" => "67890"} }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
    allow(driver).to receive(:show_vm_info).and_return(vm_info)
  end

  context "#cleanup_disks" do
    it "returns if there's no data in meta file" do
      subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      expect(subject).not_to receive(:handle_cleanup_disk)
    end

    describe "with disks to clean up" do
      let(:disk_meta_file) { {disk: [{uuid: "1234", name: "storage"}], floppy: [], dvd: []} }

      it "calls the cleanup method if a disk_meta file is defined" do
        expect(subject).to receive(:handle_cleanup_disk).
          with(machine, defined_disks, disk_meta_file["disk"]).
          and_return(true)

        subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      end
    end
  end

  context "#handle_cleanup_disk" do
    let(:disk_meta_file) { {disk: [{"uuid"=>"67890", "name"=>"storage"}], floppy: [], dvd: []} }
    let(:defined_disks) { [] }
    let(:device_info) { {port: "1", device: "0"} }

    it "removes and closes medium from guest" do
      allow(driver).to receive(:get_port_and_device).
        with("67890").
        and_return(device_info)

      expect(driver).to receive(:remove_disk).with("1", "0").and_return(true)
      expect(driver).to receive(:close_medium).with("67890").and_return(true)

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
    end

    describe "when the disk isn't attached to a guest" do
      it "only closes the medium" do
        allow(driver).to receive(:get_port_and_device).
          with("67890").
          and_return({})

        expect(driver).to receive(:close_medium).with("67890").and_return(true)

        subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
      end
    end
  end
end
