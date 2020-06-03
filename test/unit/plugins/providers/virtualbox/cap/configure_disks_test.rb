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

  let(:sata_controller) { double("controller", name: "SATA Controller", storage_bus: "SATA", maxportcount: 30) }
  let(:ide_controller) { double("controller", name: "IDE Controller", storage_bus: "IDE", maxportcount: 2) }

  let(:attachments) { [{port: "0", device: "0", uuid: "12345"},
                       {port: "1", device: "0", uuid: "67890"}]}

  let(:defined_disks) { [double("disk", name: "vagrant_primary", size: "5GB", primary: true, type: :disk),
                         double("disk", name: "disk-0", size: "5GB", primary: false, type: :disk),
                         double("disk", name: "disk-1", size: "5GB", primary: false, type: :disk),
                         double("disk", name: "disk-2", size: "5GB", primary: false, type: :disk)] }

  let(:all_disks) { [{"UUID"=>"12345",
          "Parent UUID"=>"base",
          "State"=>"created",
          "Type"=>"normal (base)",
          "Location"=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk",
          "Disk Name"=>"ubuntu-18.04-amd64-disk001",
          "Storage format"=>"VMDK",
          "Capacity"=>"65536 MBytes",
          "Encryption"=>"disabled"},
         {"UUID"=>"67890",
          "Parent UUID"=>"base",
          "State"=>"created",
          "Type"=>"normal (base)",
          "Location"=>"/home/vagrant/VirtualBox VMs/disk-0.vdi",
          "Disk Name"=>"disk-0",
          "Storage format"=>"VDI",
          "Capacity"=>"10240 MBytes",
          "Encryption"=>"disabled"},
         {"UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
          "Parent UUID"=>"base",
          "State"=>"created",
          "Type"=>"normal (base)",
          "Location"=>"/home/vagrant/VirtualBox VMs/disk-1.vdi",
          "Disk Name"=>"disk-1",
          "Storage format"=>"VDI",
          "Capacity"=>"5120 MBytes",
          "Encryption"=>"disabled"}] }

  let(:subject) { described_class }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
    allow(sata_controller).to receive(:attachments).and_return(attachments)

    allow(driver).to receive(:get_controller).with("IDE").and_return(ide_controller)
    allow(driver).to receive(:get_controller).with("SATA").and_return(sata_controller)
    allow(driver).to receive(:storage_controllers).and_return([ide_controller, sata_controller])
  end

  describe "#configure_disks" do
    let(:dsk_data) { {uuid: "1234", name: "disk"} }
    it "configures disks and returns the disks defined" do
      allow(driver).to receive(:list_hdds).and_return([])

      expect(subject).to receive(:handle_configure_disk).exactly(4).and_return(dsk_data)
      subject.configure_disks(machine, defined_disks)
    end

    context "with no disks to configure" do
      let(:defined_disks) { {} }
      it "returns empty hash if no disks to configure" do
        expect(subject.configure_disks(machine, defined_disks)).to eq({})
      end
    end

    context "with over the disk limit for a given device" do
      let(:defined_disks) { (1..31).map { |i| double("disk-#{i}", type: :disk) }.to_a }

      it "raises an exception if the disks defined exceed the limit for a SATA Controller" do
        expect{subject.configure_disks(machine, defined_disks)}.
          to raise_error(Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit)
      end
    end

    context "no SATA controller" do
      before do
        allow(driver).to receive(:get_controller).with("SATA").
          and_raise(Vagrant::Errors::VirtualBoxDisksControllerNotFound, storage_bus: "SATA")
      end

      it "raises an error" do
        expect { subject.configure_disks(machine, defined_disks) }.
          to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
      end
    end

    context "with dvd type" do
      let(:defined_disks) { [double("dvd", type: :dvd)] }
      let(:dvd_data) { {uuid: "1234", name: "dvd"} }

      it "handles configuration of the dvd" do
        allow(driver).to receive(:list_hdds).and_return([])
        expect(subject).to receive(:handle_configure_dvd).and_return(dvd_data)
        subject.configure_disks(machine, defined_disks)
      end

      context "no IDE controller" do
        before do
          allow(driver).to receive(:get_controller).with("IDE").
            and_raise(Vagrant::Errors::VirtualBoxDisksControllerNotFound, storage_bus: "IDE")
        end

        it "raises an error" do
        expect { subject.configure_disks(machine, defined_disks) }.
          to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
        end
      end
    end
  end

  describe "#get_current_disk" do
    it "gets primary disk uuid if disk to configure is primary" do
      primary_disk = subject.get_current_disk(machine, defined_disks.first, all_disks)
      expect(primary_disk).to eq(all_disks.first)
    end

    it "finds the disk to configure" do
      disk = subject.get_current_disk(machine, defined_disks[1], all_disks)
      expect(disk).to eq(all_disks[1])
    end

    it "returns nil if disk is not found" do
      disk = subject.get_current_disk(machine, defined_disks[3], all_disks)
      expect(disk).to be_nil
    end
  end

  describe "#handle_configure_disk" do
    context "when creating a new disk" do
      let(:all_disks) { [{"UUID"=>"12345",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk",
              "Disk Name"=>"ubuntu-18.04-amd64-disk001",
              "Storage format"=>"VMDK",
              "Capacity"=>"65536 MBytes",
              "Encryption"=>"disabled"}] }

      let(:disk_meta) { {uuid: "67890", name: "disk-0"} }

      it "creates a new disk if it doesn't yet exist" do
        expect(subject).to receive(:create_disk).with(machine, defined_disks[1])
          .and_return(disk_meta)

        subject.handle_configure_disk(machine, defined_disks[1], all_disks)
      end
    end

    context "when a disk needs to be resized" do
      let(:all_disks) { [{"UUID"=>"12345",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk",
              "Disk Name"=>"ubuntu-18.04-amd64-disk001",
              "Storage format"=>"VMDK",
              "Capacity"=>"65536 MBytes",
              "Encryption"=>"disabled"},
             {"UUID"=>"67890",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/disk-0.vdi",
              "Disk Name"=>"disk-0",
              "Storage format"=>"VDI",
              "Capacity"=>"10240 MBytes",
              "Encryption"=>"disabled"}] }

      it "resizes a disk" do
        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(all_disks[1])

        expect(subject).to receive(:compare_disk_size).
          with(machine, defined_disks[1], all_disks[1]).and_return(true)

        expect(subject).to receive(:resize_disk).
          with(machine, defined_disks[1], all_disks[1]).and_return(true)

        subject.handle_configure_disk(machine, defined_disks[1], all_disks)
      end
    end

    context "if no additional disk configuration is required" do
      let(:all_disks) { [{"UUID"=>"12345",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk",
              "Disk Name"=>"ubuntu-18.04-amd64-disk001",
              "Storage format"=>"VMDK",
              "Capacity"=>"65536 MBytes",
              "Encryption"=>"disabled"},
             {"UUID"=>"67890",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/disk-0.vdi",
              "Disk Name"=>"disk-0",
              "Storage format"=>"VDI",
              "Capacity"=>"10240 MBytes",
              "Encryption"=>"disabled"}] }

      let(:disk_info) { {port: "1", device: "0"} }

      it "reattaches disk if vagrant defined disk exists but is not attached to guest" do
        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(all_disks[1])

        expect(subject).to receive(:compare_disk_size).
          with(machine, defined_disks[1], all_disks[1]).and_return(false)

        expect(driver).to receive(:get_port_and_device).with("67890").
          and_return({})

        expect(driver).to receive(:attach_disk).with((disk_info[:port].to_i + 1).to_s,
                                                     disk_info[:device],
                                                     all_disks[1]["Location"])

        subject.handle_configure_disk(machine, defined_disks[1], all_disks)
      end

      it "does nothing if all disks are properly configured" do
        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(all_disks[1])

        expect(subject).to receive(:compare_disk_size).
          with(machine, defined_disks[1], all_disks[1]).and_return(false)

        expect(driver).to receive(:get_port_and_device).with("67890").
          and_return(disk_info)

        subject.handle_configure_disk(machine, defined_disks[1], all_disks)
      end
    end
  end

  describe "#compare_disk_size" do
    let(:disk_config_small) { double("disk", name: "disk-0", size: 1073741824.0, primary: false, type: :disk) }
    let(:disk_config_large) { double("disk", name: "disk-0", size: 68719476736.0, primary: false, type: :disk) }

    it "shows a warning if user attempts to shrink size" do
      expect(machine.ui).to receive(:warn)
      expect(subject.compare_disk_size(machine, disk_config_small, all_disks[1])).to be_falsey
    end

    it "returns true if requested size is bigger than current size" do
      expect(subject.compare_disk_size(machine, disk_config_large, all_disks[1])).to be_truthy
    end
  end

  describe "#create_disk" do
    let(:disk_config) { double("disk", name: "disk-0", size: 1073741824.0,
                               primary: false, type: :disk, disk_ext: "vdi",
                               provider_config: nil) }
    let(:vm_info) { {"CfgFile"=>"/home/vagrant/VirtualBox VMs/disks/"} }
    let(:disk_file) { "/home/vagrant/VirtualBox VMs/disk-0.vdi" }
    let(:disk_data) { "Medium created. UUID: 67890\n" }

    let(:port_and_device) { {port: "1", device: "0"} }

    it "creates a disk and attaches it to a guest" do
      expect(driver).to receive(:show_vm_info).and_return(vm_info)

      expect(driver).to receive(:create_disk).
        with(disk_file, disk_config.size, "VDI").and_return(disk_data)

      expect(subject).to receive(:get_next_port).with(machine, sata_controller).
        and_return(port_and_device)

      expect(driver).to receive(:attach_disk).with(port_and_device[:port],
                                                   port_and_device[:device],
                                                   disk_file)

      subject.create_disk(machine, disk_config)
    end
  end

  describe ".get_next_port" do
    it "determines the next available port and device to use" do
      dsk_info = subject.get_next_port(machine, sata_controller)
      expect(dsk_info[:port]).to eq("2")
      expect(dsk_info[:device]).to eq("0")
    end

    context "guest with an IDE controller" do
      let(:attachments) { [{port: "0", device: "0", uuid: "12345"},
                           {port: "0", device: "1", uuid: "67890"}] }

      before do
        allow(ide_controller).to receive(:attachments).and_return(attachments)
      end

      it "determines the next available port and device to use" do
        dsk_info = subject.get_next_port(machine, ide_controller)
        expect(dsk_info[:port]).to eq("1")
        expect(dsk_info[:device]).to eq("0")
      end

      context "that is full" do
        let(:attachments) { [{port: "0", device: "0", uuid: "11111"},
                             {port: "0", device: "1", uuid: "22222"},
                             {port: "1", device: "0", uuid: "33333"},
                             {port: "1", device: "1", uuid: "44444"}] }

        it "raises an error" do
          expect { subject.get_next_port(machine, ide_controller) }
            .to raise_error(Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit)
        end
      end
    end
  end

  describe "#resize_disk" do
    context "when a disk is vmdk format" do
      let(:disk_config) { double("disk", name: "vagrant_primary", size: 1073741824.0,
                                 primary: false, type: :disk, disk_ext: "vmdk",
                                 provider_config: nil) }
      let(:attach_info) { {port: "0", device: "0"} }
      let(:vdi_disk_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vdi" }
      let(:vmdk_disk_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk" }

      it "converts the disk to vdi, resizes it, and converts back to vmdk" do
        expect(FileUtils).to receive(:mv).with(vmdk_disk_file, "#{vmdk_disk_file}.backup").
          and_return(true)

        expect(driver).to receive(:get_port_and_device).with("12345").
          and_return(attach_info)

        expect(driver).to receive(:vmdk_to_vdi).with(all_disks[0]["Location"]).
          and_return(vdi_disk_file)

        expect(driver).to receive(:resize_disk).with(vdi_disk_file, disk_config.size.to_i).
          and_return(true)

        expect(driver).to receive(:remove_disk).with(attach_info[:port], attach_info[:device], sata_controller.name).
          and_return(true)
        expect(driver).to receive(:close_medium).with("12345")

        expect(driver).to receive(:vdi_to_vmdk).with(vdi_disk_file).
          and_return(vmdk_disk_file)

        expect(driver).to receive(:attach_disk).
          with(attach_info[:port], attach_info[:device], vmdk_disk_file, "hdd").and_return(true)
        expect(driver).to receive(:close_medium).with(vdi_disk_file).and_return(true)

        expect(driver).to receive(:list_hdds).and_return(all_disks)

        expect(FileUtils).to receive(:remove).with("#{vmdk_disk_file}.backup", force: true).
          and_return(true)

        subject.resize_disk(machine, disk_config, all_disks[0])
      end

      it "reattaches original disk if something goes wrong" do
        expect(FileUtils).to receive(:mv).with(vmdk_disk_file, "#{vmdk_disk_file}.backup").
          and_return(true)

        expect(driver).to receive(:get_port_and_device).with("12345").
          and_return(attach_info)

        expect(driver).to receive(:vmdk_to_vdi).with(all_disks[0]["Location"]).
          and_return(vdi_disk_file)

        expect(driver).to receive(:resize_disk).with(vdi_disk_file, disk_config.size.to_i).
          and_return(true)

        expect(driver).to receive(:remove_disk).with(attach_info[:port], attach_info[:device], sata_controller.name).
          and_return(true)
        expect(driver).to receive(:close_medium).with("12345")

        allow(driver).to receive(:vdi_to_vmdk).and_raise(StandardError)

        expect(FileUtils).to receive(:mv).with("#{vmdk_disk_file}.backup", vmdk_disk_file, force: true).
          and_return(true)

        expect(driver).to receive(:attach_disk).
          with(attach_info[:port], attach_info[:device], vmdk_disk_file, "hdd").and_return(true)
        expect(driver).to receive(:close_medium).with(vdi_disk_file).and_return(true)

        expect{subject.resize_disk(machine, disk_config, all_disks[0])}.to raise_error(Exception)
      end
    end

    context "when a disk is vdi format" do
      let(:disk_config) { double("disk", name: "disk-0", size: 1073741824.0,
                                 primary: false, type: :disk, disk_ext: "vdi",
                                 provider_config: nil) }
      it "resizes the disk" do
        expect(driver).to receive(:resize_disk).with(all_disks[1]["Location"], disk_config.size.to_i)

        subject.resize_disk(machine, disk_config, all_disks[1])
      end
    end
  end

  describe "#vmdk_to_vdi" do
    it "converts a disk from vmdk to vdi" do
    end
  end

  describe "#vdi_to_vmdk" do
    it "converts a disk from vdi to vmdk" do
    end
  end

  describe ".handle_configure_dvd" do
    let(:dvd_config) { double("dvd", file: "/tmp/untitled.iso", name: "dvd1") }

    before do
      allow(subject).to receive(:get_next_port).with(machine, ide_controller).
        and_return({device: "0", port: "0"})
      allow(ide_controller).to receive(:attachments).and_return(
        [port: "0", device: "0", uuid: "12345"]
      )
    end

    it "returns the UUID of the newly-attached dvd" do
      expect(driver).to receive(:attach_disk).with("0", "0", "/tmp/untitled.iso", "dvddrive")

      disk_meta = subject.handle_configure_dvd(machine, dvd_config)
      expect(disk_meta[:uuid]).to eq("12345")
    end
  end
end
