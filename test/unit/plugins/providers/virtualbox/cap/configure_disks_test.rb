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

  let(:storage_controllers) { double("storage controllers") }

  let(:controller) { double("controller", name: "controller", maxportcount: 30, devices_per_port: 1, limit: 30) }

  let(:attachments) { [{:port=>"0", :device=>"0",
                      :uuid=>"12345",
                      :storage_format=>"VMDK",
                      :capacity=>"65536 MBytes",
                      :disk_name=>"ubuntu-18.04-amd64-disk001",
                      :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"},
                     {:port=>"1", :device=>"0",
                      :uuid=>"67890",
                      :storage_format=>"VDI",
                      :capacity=>"10240 MBytes",
                      :disk_name=>"disk-0",
                      :location=>"/home/vagrant/VirtualBox VMs/disk-0.vdi"},
                     {:port=>"2", :device=>"0",
                      :uuid=>"10111",
                      :storage_format=>"VDI",
                      :capacity=>"10240 MBytes",
                      :disk_name=>"disk-1",
                      :location=>"/home/vagrant/VirtualBox VMs/disk-1.vdi"}] }

  let(:defined_disks) { [double("disk", name: "vagrant_primary", size: Vagrant::Util::Numeric::string_to_bytes("65GB"), primary: true, type: :disk),
                         double("disk", name: "disk-0", size: Vagrant::Util::Numeric::string_to_bytes("10GB"), primary: false, type: :disk),
                         double("disk", name: "disk-1", size: "10GB", primary: false, type: :disk),
                         double("disk", name: "disk-2", size: "5GB", primary: false, type: :disk)] }


  let(:all_disks) { [{:port=>"0", :device=>"0",
                      :uuid=>"12345",
                      :storage_format=>"VMDK",
                      :capacity=>"65536 MBytes",
                      :disk_name=>"ubuntu-18.04-amd64-disk001",
                      :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"},
                     {:port=>"1", :device=>"0",
                      :uuid=>"67890",
                      :storage_format=>"VDI",
                      :capacity=>"10240 MBytes",
                      :disk_name=>"disk-0",
                      :location=>"/home/vagrant/VirtualBox VMs/disk-0.vdi"},
                     {:port=>"2", :device=>"0",
                      :uuid=>"10111",
                      :storage_format=>"VDI",
                      :capacity=>"10240 MBytes",
                      :disk_name=>"disk-1",
                      :location=>"/home/vagrant/VirtualBox VMs/disk-1.vdi"}] }

  let(:list_hdds_result) { [{"UUID"=>"12345",
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
    allow(controller).to receive(:attachments).and_return(attachments)
    allow(storage_controllers).to receive(:get_controller).with(controller.name).and_return(controller)
    allow(storage_controllers).to receive(:first).and_return(controller)
    allow(storage_controllers).to receive(:size).and_return(1)
    allow(driver).to receive(:read_storage_controllers).and_return(storage_controllers)
    allow(driver).to receive(:list_hdds).and_return(list_hdds_result)
  end

  describe "#configure_disks" do
    let(:dsk_data) { {uuid: "1234", name: "disk"} }
    let(:dvd) { double("dvd", type: :dvd, name: "dvd", primary: false) }

    before do
      allow(driver).to receive(:list_hdds).and_return([])
    end

    it "configures disks and returns the disks defined" do
      expect(subject).to receive(:handle_configure_disk).with(machine, anything, controller.name).
        exactly(4).and_return(dsk_data)
      subject.configure_disks(machine, defined_disks)
    end

    it "configures dvd and returns the disks defined" do
      defined_disks = [ dvd ]

      expect(subject).to receive(:handle_configure_dvd).with(machine, dvd, controller.name).
        and_return({})
      subject.configure_disks(machine, defined_disks)
    end

    context "with no disks to configure" do
      let(:defined_disks) { {} }

      it "returns empty hash if no disks to configure" do
        expect(subject.configure_disks(machine, defined_disks)).to eq({})
      end
    end

    # NOTE: In this scenario, one slot must be reserved for the primary
    # disk, so the controller limit goes down by 1 when there is no primary
    # disk defined in the config.
    context "with over the disk limit for a given device" do
      let(:defined_disks) { (1..controller.limit).map { |i| double("disk-#{i}", type: :disk, primary: false) }.to_a }

      it "raises an exception if the disks defined exceed the limit" do
        expect{subject.configure_disks(machine, defined_disks)}.
          to raise_error(Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit)
      end
    end

    # hashicorp/bionic64
    context "with more than one storage controller" do
      let(:controller1) { double("controller1", name: "IDE Controller", maxportcount: 2, devices_per_port: 2, limit: 4) }
      let(:controller2) { double("controller2", name: "SATA Controller", maxportcount: 30, devices_per_port: 1, limit: 30) }

      before do
        allow(storage_controllers).to receive(:size).and_return(2)
        allow(storage_controllers).to receive(:get_controller).with(controller1.name).
          and_return(controller1)
        allow(storage_controllers).to receive(:get_controller).with(controller2.name).
          and_return(controller2)
        allow(storage_controllers).to receive(:get_dvd_controller).and_return(controller1)
        allow(storage_controllers).to receive(:get_primary_controller).and_return(controller2)
      end

      it "attaches disks to the primary controller" do
        expect(subject).to receive(:handle_configure_disk).with(machine, anything, controller2.name).
          exactly(4).and_return(dsk_data)
        subject.configure_disks(machine, defined_disks)
      end

      it "attaches dvds to the secondary controller" do
        defined_disks = [ dvd ]

        expect(subject).to receive(:handle_configure_dvd).with(machine, dvd, controller1.name).
          and_return({})
        subject.configure_disks(machine, defined_disks)
      end

      it "raises an error if there are more than 4 dvds configured" do
        defined_disks = [
          double("dvd", name: "installer1", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer2", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer3", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer4", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer5", type: :dvd, file: "installer.iso", primary: false)
        ]

        expect { subject.configure_disks(machine, defined_disks) }.
          to raise_error(Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit)
      end

      it "attaches multiple dvds" do
        defined_disks = [
          double("dvd", name: "installer1", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer2", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer3", type: :dvd, file: "installer.iso", primary: false),
          double("dvd", name: "installer4", type: :dvd, file: "installer.iso", primary: false),
        ]

        expect(subject).to receive(:handle_configure_dvd).exactly(4).times.and_return({})

        subject.configure_disks(machine, defined_disks)
      end
    end
  end

  describe "#get_current_disk" do
    it "gets primary disk uuid if disk to configure is primary" do
      allow(storage_controllers).to receive(:get_primary_attachment).and_return(attachments[0])
      primary_disk = subject.get_current_disk(machine, defined_disks.first, all_disks)
      expect(primary_disk).to eq(all_disks.first)
    end

    it "raises an error if primary disk can't be found" do
      allow(storage_controllers).to receive(:get_primary_attachment).and_raise(Vagrant::Errors::VirtualBoxDisksPrimaryNotFound)
      expect { subject.get_current_disk(machine, defined_disks.first, all_disks) }.
        to raise_error(Vagrant::Errors::VirtualBoxDisksPrimaryNotFound)
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
      let(:all_disks) { [{:port=>"0", :device=>"0",
                          :uuid=>"12345",
                          :storage_format=>"VMDK",
                          :capacity=>"65536 MBytes",
                          :disk_name=>"ubuntu-18.04-amd64-disk001",
                          :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"}] }

      let(:list_hdds_result) { [{"UUID"=>"12345",
                            "Parent UUID"=>"base",
                            "State"=>"created",
                            "Type"=>"normal (base)",
                            "Location"=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk",
                            "Disk Name"=>"ubuntu-18.04-amd64-disk001",
                            "Storage format"=>"VMDK",
                            "Capacity"=>"65536 MBytes",
                            "Encryption"=>"disabled"}] }

      let(:disk_meta) { {uuid: "67890", name: "disk-0", controller: "controller", port: "1", device: "1"} }

      it "creates a new disk if it doesn't yet exist" do
        expect(subject).to receive(:create_disk).with(machine, defined_disks[1], controller)
          .and_return(disk_meta)
        expect(controller).to receive(:attachments).and_return(all_disks)

        expect(storage_controllers).to receive(:get_primary_attachment)
          .and_return(all_disks[0])

        subject.handle_configure_disk(machine, defined_disks[1], controller.name)
      end

      it "includes disk attachment info in metadata" do
        expect(subject).to receive(:create_disk).with(machine, defined_disks[1], controller)
          .and_return(disk_meta)
        expect(controller).to receive(:attachments).and_return(all_disks)
        expect(storage_controllers).to receive(:get_primary_attachment)
          .and_return(all_disks[0])

        disk_metadata = subject.handle_configure_disk(machine, defined_disks[1], controller.name)
        expect(disk_metadata).to have_key(:controller)
        expect(disk_metadata).to have_key(:port)
        expect(disk_metadata).to have_key(:device)
        expect(disk_metadata).to have_key(:name)
      end
    end

    context "when a disk needs to be resized" do
      let(:all_disks) { [{:port=>"0", :device=>"0",
                          :uuid=>"12345",
                          :storage_format=>"VMDK",
                          :capacity=>"65536 MBytes",
                          :disk_name=>"ubuntu-18.04-amd64-disk001",
                          :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"},
                         {:port=>"1", :device=>"0",
                          :uuid=>"67890",
                          :storage_format=>"VDI",
                          :capacity=>"10240 MBytes",
                          :disk_name=>"disk-0",
                          :location=>"/home/vagrant/VirtualBox VMs/disk-0.vdi"}] }

      it "resizes a disk" do
        expect(controller).to receive(:attachments).and_return(all_disks)

        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(all_disks[1])

        expect(subject).to receive(:compare_disk_size).
          with(machine, defined_disks[1], all_disks[1]).and_return(true)

        expect(subject).to receive(:resize_disk).
          with(machine, defined_disks[1], all_disks[1], controller).and_return({})

        subject.handle_configure_disk(machine, defined_disks[1], controller.name)
      end
    end

    context "if no additional disk configuration is required" do
      let(:all_disks) { [{:port=>"0", :device=>"0",
                          :uuid=>"12345",
                          :storage_format=>"VMDK",
                          :capacity=>"65536 MBytes",
                          :disk_name=>"ubuntu-18.04-amd64-disk001",
                          :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"},
                         {:port=>"1", :device=>"0",
                          :uuid=>"67890",
                          :storage_format=>"VDI",
                          :capacity=>"10240 MBytes",
                          :disk_name=>"disk-0",
                          :location=>"/home/vagrant/VirtualBox VMs/disk-0.vdi"}] }

      let(:disk_info) { {port: "1", device: "0"} }

      let(:attachments) { [{:port=>"0", :device=>"0",
                          :uuid=>"12345",
                          :disk_name=>"ubuntu-18.04-amd64-disk001",
                          :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"},
                         {:port=>"1", :device=>"0",
                          :uuid=>"67890",
                          :disk_name=>"disk-0",
                          :location=>"/home/vagrant/VirtualBox VMs/disk-0.vdi"}] }

      it "reattaches disk if vagrant defined disk exists but is not attached to guest" do
        expect(controller).to receive(:attachments).and_return(all_disks)

        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(nil)

        expect(storage_controllers).to receive(:get_primary_attachment)
          .and_return(all_disks[0])

        expect(driver).to receive(:attach_disk).with(controller.name,
                                                     (disk_info[:port].to_i + 1).to_s,
                                                     disk_info[:device],
                                                     "hdd",
                                                     all_disks[1][:location])

        subject.handle_configure_disk(machine, defined_disks[1], controller.name)
      end

      it "does nothing if all disks are properly configured" do
        expect(controller).to receive(:attachments).and_return(all_disks)

        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(all_disks[1])

        expect(subject).to receive(:compare_disk_size).
          with(machine, defined_disks[1], all_disks[1]).and_return(false)

        subject.handle_configure_disk(machine, defined_disks[1], controller.name)
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

      expect(subject).to receive(:get_next_port).with(machine, controller).
        and_return(port_and_device)

      expect(driver).to receive(:attach_disk).with(controller.name,
                                                   port_and_device[:port],
                                                   port_and_device[:device],
                                                   "hdd",
                                                   disk_file)

      subject.create_disk(machine, disk_config, controller)
    end
  end

  describe ".get_next_port" do
    let(:attachments) { [{:port=>"0", :device=>"0",
                        :uuid=>"12345",
                        :disk_name=>"ubuntu-18.04-amd64-disk001",
                        :location=>"/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk"},
                       {:port=>"1", :device=>"0",
                        :uuid=>"67890",
                        :disk_name=>"disk-0",
                        :location=>"/home/vagrant/VirtualBox VMs/disk-0.vdi"}] }
    it "determines the next available port and device to use" do
      dsk_info = subject.get_next_port(machine, controller)
      expect(dsk_info[:port]).to eq("2")
      expect(dsk_info[:device]).to eq("0")
    end

    context "with IDE controller" do
      let(:controller) {
        double("controller", name: "IDE", maxportcount: 2, devices_per_port: 2, limit: 4)
      }

      let(:attachments) { [] }

      it "attaches to port 0, device 0" do
        dsk_info = subject.get_next_port(machine, controller)
        expect(dsk_info[:port]).to eq("0")
        expect(dsk_info[:device]).to eq("0")
      end

      context "with 1 device" do
        let(:attachments) { [{port:"0", device: "0"}] }

        it "attaches to the next device on that port" do
          dsk_info = subject.get_next_port(machine, controller)
          expect(dsk_info[:port]).to eq("0")
          expect(dsk_info[:device]).to eq("1")
        end
      end
    end

    context "with SCSI controller" do
      let(:controller) {
        double("controller", name: "SCSI", maxportcount: 16, devices_per_port: 1, limit: 16)
      }

      let(:attachments) { [] }

      let(:vm_info) { {"SATA Controller-ImageUUID-0-0" => "12345",
                       "SATA Controller-ImageUUID-1-0" => "67890"} }

      it "determines the next available port and device to use" do
        allow(driver).to receive(:show_vm_info).and_return(vm_info)
        dsk_info = subject.get_next_port(machine, controller)
        expect(dsk_info[:port]).to eq("0")
        expect(dsk_info[:device]).to eq("0")
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

        expect(driver).to receive(:vmdk_to_vdi).with(all_disks[0][:location]).
          and_return(vdi_disk_file)

        expect(driver).to receive(:resize_disk).with(vdi_disk_file, disk_config.size.to_i).and_return(true)

        expect(driver).to receive(:remove_disk).with(controller.name, attach_info[:port], attach_info[:device]).
          and_return(true)
        expect(driver).to receive(:close_medium).with("12345")

        expect(driver).to receive(:vdi_to_vmdk).with(vdi_disk_file).
          and_return(vmdk_disk_file)

        expect(driver).to receive(:attach_disk).
          with(controller.name, attach_info[:port], attach_info[:device], "hdd", vmdk_disk_file).and_return(true)
        expect(driver).to receive(:close_medium).with(vdi_disk_file).and_return(true)

        expect(driver).to receive(:read_storage_controllers)
        expect(storage_controllers).to receive(:get_controller)

        expect(FileUtils).to receive(:remove).with("#{vmdk_disk_file}.backup", force: true).
          and_return(true)

        subject.resize_disk(machine, disk_config, all_disks[0], controller)
      end

      it "reattaches original disk if something goes wrong" do
        expect(FileUtils).to receive(:mv).with(vmdk_disk_file, "#{vmdk_disk_file}.backup").
          and_return(true)

        expect(driver).to receive(:vmdk_to_vdi).with(all_disks[0][:location]).
          and_return(vdi_disk_file)

        expect(driver).to receive(:resize_disk).with(vdi_disk_file, disk_config.size.to_i).and_return(true)

        expect(driver).to receive(:remove_disk).with(controller.name, attach_info[:port], attach_info[:device]).
          and_return(true)
        expect(driver).to receive(:close_medium).with("12345")

        allow(driver).to receive(:vdi_to_vmdk).and_raise(StandardError)

        expect(subject).to receive(:recover_from_resize).with(machine, all_disks[0], "#{vmdk_disk_file}.backup", all_disks[0], vdi_disk_file, controller)

        expect{subject.resize_disk(machine, disk_config, all_disks[0], controller)}.to raise_error(Exception)
      end
    end

    context "when a disk is vdi format" do
      let(:disk_config) { double("disk", name: "disk-0", size: 1073741824.0,
                                 primary: false, type: :disk, disk_ext: "vdi",
                                 provider_config: nil) }
      it "resizes the disk" do
        expect(driver).to receive(:resize_disk).with(all_disks[1][:location], disk_config.size.to_i)

        subject.resize_disk(machine, disk_config, all_disks[1], controller)
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

  describe ".recover_from_resize" do
    let(:disk_config) { double("disk", name: "vagrant_primary", size: 1073741824.0,
                               primary: false, type: :disk, disk_ext: "vmdk",
                               provider_config: nil) }
    let(:attach_info) { {port: "0", device: "0"} }
    let(:vdi_disk_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vdi" }
    let(:vmdk_disk_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk" }
    let(:vmdk_backup_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk.backup" }

    it "reattaches the original disk file and closes the cloned medium" do
      expect(FileUtils).to receive(:mv).with(vmdk_backup_file, vmdk_disk_file, force: true).
        and_return(true)

      expect(driver).to receive(:attach_disk).
        with(controller.name, attach_info[:port], attach_info[:device], "hdd", vmdk_disk_file).and_return(true)

      expect(driver).to receive(:close_medium).with(vdi_disk_file).and_return(true)

      subject.recover_from_resize(machine, attach_info, vmdk_backup_file, all_disks[0], vdi_disk_file, controller)
    end
  end

  describe ".handle_configure_dvd" do
    let(:dvd_config) { double("dvd", file: "/tmp/untitled.iso", name: "dvd1", primary: false) }

    before do
      allow(subject).to receive(:get_next_port).with(machine, controller).
        and_return({device: "0", port: "0"})
      allow(controller).to receive(:attachments).and_return(
        [port: "0", device: "0", uuid: "12345"]
      )
    end

    it "includes disk attachment info in metadata" do
      expect(driver).to receive(:attach_disk).with(controller.name, "0", "0", "dvddrive", "/tmp/untitled.iso")

      dvd_metadata = subject.handle_configure_dvd(machine, dvd_config, controller.name)
      expect(dvd_metadata[:uuid]).to eq("12345")
      expect(dvd_metadata).to have_key(:controller)
      expect(dvd_metadata).to have_key(:port)
      expect(dvd_metadata).to have_key(:device)
      expect(dvd_metadata).to have_key(:name)
    end
  end
end
