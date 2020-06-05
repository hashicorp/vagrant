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

  let(:sata_controller) { double("controller", name: "SATA Controller", storage_bus: "SATA", maxportcount: 30) }
  let(:ide_controller) { double("controller", name: "IDE Controller", storage_bus: "IDE", maxportcount: 2) }

  let(:attachments) { [{port: "0", device: "0", uuid: "12345"},
                       {port: "1", device: "0", uuid: "67890"}]}

  let(:storage_controllers) { [ controller ] }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
    allow(sata_controller).to receive(:attachments).and_return(attachments)

    allow(driver).to receive(:get_controller).with("IDE").and_return(ide_controller)
    allow(driver).to receive(:get_controller).with("SATA").and_return(sata_controller)
    allow(driver).to receive(:storage_controllers).and_return([ide_controller, sata_controller])
  end

  describe "#cleanup_disks" do
    it "returns if there's no data in meta file" do
      subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      expect(subject).not_to receive(:handle_cleanup_disk)
    end

    context "with disks to clean up" do
      let(:disk_meta_file) { {disk: [{uuid: "1234", name: "storage"}], floppy: [], dvd: []} }

      it "calls the cleanup method if a disk_meta file is defined" do
        expect(subject).to receive(:handle_cleanup_disk).
          with(machine, defined_disks, disk_meta_file["disk"]).
          and_return(true)

        subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      end

      it "raises an error if primary disk can't be found" do
        allow(sata_controller).to receive(:attachments).and_return([])
        expect { subject.cleanup_disks(machine, defined_disks, disk_meta_file) }.
          to raise_error(Vagrant::Errors::VirtualBoxDisksPrimaryNotFound)
      end
    end

    context "with dvd attached" do
      let(:disk_meta_file) { {dvd: [{uuid: "12345", name: "iso"}]} }

      it "calls the cleanup method if a disk_meta file is defined" do
        expect(subject).to receive(:handle_cleanup_dvd).
          with(machine, defined_disks, disk_meta_file["dvd"]).
          and_return(true)

        subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      end
    end
  end

  describe "#handle_cleanup_disk" do
    let(:disk_meta_file) { {disk: [{"uuid"=>"67890", "name"=>"storage"}], floppy: [], dvd: []} }
    let(:defined_disks) { [] }
    let(:device_info) { {port: "1", device: "0"} }

    it "removes and closes medium from guest" do
      allow(driver).to receive(:get_port_and_device).
        with("67890").
        and_return(device_info)

      expect(driver).to receive(:remove_disk).with("1", "0", sata_controller.name).and_return(true)
      expect(driver).to receive(:close_medium).with("67890").and_return(true)

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
    end

    context "when the disk isn't attached to a guest" do
      it "only closes the medium" do
        allow(driver).to receive(:get_port_and_device).
          with("67890").
          and_return({})

        expect(driver).to receive(:close_medium).with("67890").and_return(true)

        subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
      end
    end
  end

  describe "#handle_cleanup_dvd" do
    let(:attachments) { [{port: "0", device: "0", uuid: "1234"}] }

    let(:disk_meta_file) { {dvd: [{"uuid" => "1234", "name" => "iso"}]} }
    let(:defined_disks) { [] }

    before do
      allow(ide_controller).to receive(:attachments).and_return(attachments)
    end

    it "removes the medium from guest" do
      expect(driver).to receive(:remove_disk).with("0", "0", "IDE Controller").and_return(true)

      subject.handle_cleanup_dvd(machine, defined_disks, disk_meta_file[:dvd])
    end

    context "multiple copies of the same ISO attached" do
      let(:attachments) { [{port: "0", device: "0", uuid: "1234"},
                           {port: "0", device: "1", uuid: "1234"}] }

      it "removes all media with that UUID" do
        expect(driver).to receive(:remove_disk).with("0", "0", "IDE Controller").and_return(true)
        expect(driver).to receive(:remove_disk).with("0", "1", "IDE Controller").and_return(true)

        subject.handle_cleanup_dvd(machine, defined_disks, disk_meta_file[:dvd])
      end
    end
  end
end
