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

  let(:attachments) { [{port: "0", device: "0", uuid: "12345"},
                       {port: "1", device: "0", uuid: "67890"}]}

  let(:controller) { double("controller", name: "controller", limit: 30, storage_bus: "SATA", maxportcount: 30) }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
    allow(controller).to receive(:attachments).and_return(attachments)
    allow(driver).to receive(:read_storage_controllers).and_return([controller])
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
        allow(controller).to receive(:attachments).and_return([])
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
    let(:disk_meta_file) { { disk: [{ "uuid" => "67890", "name" => "storage", "controller" => "controller", "port" => "1", "device" => "0" }], floppy: [], dvd: [] } }

    let(:defined_disks) { [] }
    let(:device_info) { {port: "1", device: "0"} }

    it "removes and closes medium from guest" do
      expect(driver).to receive(:remove_disk).with("controller", "1", "0").and_return(true)
      expect(driver).to receive(:close_medium).with("67890").and_return(true)

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
    end

    context "when the disk isn't attached to a guest" do
      let(:attachments) { [{port: "0", device: "0", uuid: "12345"}] }

      it "only closes the medium" do
        expect(driver).to receive(:close_medium).with("67890").and_return(true)

        subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
      end
    end
  end

  describe "#handle_cleanup_dvd" do
    let(:attachments) { [{port: "0", device: "0", uuid: "1234"}] }

    let(:disk_meta_file) { {dvd: [{"uuid" => "1234", "name" => "iso", "port" => "0", "device" => "0", "controller" => "controller" }]} }

    let(:defined_disks) { [] }

    it "removes the medium from guest" do
      expect(driver).to receive(:remove_disk).with("controller", "0", "0").and_return(true)

      subject.handle_cleanup_dvd(machine, defined_disks, disk_meta_file[:dvd])
    end
  end
end
