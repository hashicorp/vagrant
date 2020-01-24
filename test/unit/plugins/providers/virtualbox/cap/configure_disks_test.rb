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

  let(:defined_disks) { [double("disk", name: "vagrant_primary", size: "5GB", primary: true, type: :disk),
                         double("disk", name: "disk-0", size: "5GB", primary: false, type: :disk),
                         double("disk", name: "disk-1", size: "5GB", primary: false, type: :disk),
                         double("disk", name: "disk-2", size: "5GB", primary: false, type: :disk)] }

  let(:all_disks) { [{"UUID"=>"12345",
          "Parent UUID"=>"base",
          "State"=>"created",
          "Type"=>"normal (base)",
          "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/ubuntu-18.04-amd64-disk001.vmdk",
          "Disk Name"=>"ubuntu-18.04-amd64-disk001",
          "Storage format"=>"VMDK",
          "Capacity"=>"65536 MBytes",
          "Encryption"=>"disabled"},
         {"UUID"=>"67890",
          "Parent UUID"=>"base",
          "State"=>"created",
          "Type"=>"normal (base)",
          "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/disk-0.vdi",
          "Disk Name"=>"disk-0",
          "Storage format"=>"VDI",
          "Capacity"=>"10240 MBytes",
          "Encryption"=>"disabled"},
         {"UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
          "Parent UUID"=>"base",
          "State"=>"created",
          "Type"=>"normal (base)",
          "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/disk-1.vdi",
          "Disk Name"=>"disk-1",
          "Storage format"=>"VDI",
          "Capacity"=>"5120 MBytes",
          "Encryption"=>"disabled"}] }

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

  context "#handle_configure_disk" do
    describe "when creating a new disk" do
      let(:all_disks) { [{"UUID"=>"12345",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/ubuntu-18.04-amd64-disk001.vmdk",
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

    describe "when a disk needs to be resized" do
      let(:all_disks) { [{"UUID"=>"12345",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/ubuntu-18.04-amd64-disk001.vmdk",
              "Disk Name"=>"ubuntu-18.04-amd64-disk001",
              "Storage format"=>"VMDK",
              "Capacity"=>"65536 MBytes",
              "Encryption"=>"disabled"},
             {"UUID"=>"67890",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/disk-0.vdi",
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

    describe "if no additional disk configuration is required" do
      let(:all_disks) { [{"UUID"=>"12345",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/ubuntu-18.04-amd64-disk001.vmdk",
              "Disk Name"=>"ubuntu-18.04-amd64-disk001",
              "Storage format"=>"VMDK",
              "Capacity"=>"65536 MBytes",
              "Encryption"=>"disabled"},
             {"UUID"=>"67890",
              "Parent UUID"=>"base",
              "State"=>"created",
              "Type"=>"normal (base)",
              "Location"=>"/home/vagrant/VirtualBox VMs/vagrant-sandbox_1579888721946_75923/disk-0.vdi",
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

  context "#compare_disk_size" do
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

  context "#create_disk" do
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

      expect(subject).to receive(:get_next_port).with(machine).
        and_return(port_and_device)

      expect(driver).to receive(:attach_disk).with(port_and_device[:port],
                                                   port_and_device[:device],
                                                   disk_file)

      subject.create_disk(machine, disk_config)
    end
  end

  context "#get_next_port" do
    it "determines the next available port to use" do
      dsk_info = subject.get_next_port(machine)
      expect(dsk_info[:device]).to eq("0")
      expect(dsk_info[:port]).to eq("2")
    end
  end

  context "#resize_disk" do
    describe "when a disk is vmdk format" do
      let(:disk_config) { double("disk", name: "vagrant_primary", size: 1073741824.0,
                                 primary: false, type: :disk, disk_ext: "vmdk",
                                 provider_config: nil) }
      let(:attach_info) { {port: "0", device: "0"} }
      let(:vdi_disk_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vdi" }
      let(:vmdk_disk_file) { "/home/vagrant/VirtualBox VMs/ubuntu-18.04-amd64-disk001.vmdk" }

      it "converts the disk to vdi, resizes it, and converts back to vmdk" do
        expect(driver).to receive(:get_port_and_device).with("12345").
          and_return(attach_info)

        expect(subject).to receive(:vmdk_to_vdi).with(driver, all_disks[0]["Location"]).
          and_return(vdi_disk_file)

        expect(driver).to receive(:resize_disk).with(vdi_disk_file, disk_config.size.to_i).
          and_return(true)

        expect(driver).to receive(:remove_disk).with(attach_info[:port], attach_info[:device]).
          and_return(true)
        expect(driver).to receive(:close_medium).with("12345")

        expect(subject).to receive(:vdi_to_vmdk).with(driver, vdi_disk_file).
          and_return(vmdk_disk_file)

        expect(driver).to receive(:attach_disk).
          with(attach_info[:port], attach_info[:device], vmdk_disk_file, "hdd").and_return(true)
        expect(driver).to receive(:close_medium).with(vdi_disk_file).and_return(true)

        expect(driver).to receive(:list_hdds).and_return(all_disks)

        subject.resize_disk(machine, disk_config, all_disks[0])
      end
    end

    describe "when a disk is vdi format" do
      let(:disk_config) { double("disk", name: "disk-0", size: 1073741824.0,
                                 primary: false, type: :disk, disk_ext: "vdi",
                                 provider_config: nil) }
      it "resizes the disk" do
        expect(driver).to receive(:resize_disk).with(all_disks[1]["Location"], disk_config.size.to_i)

        subject.resize_disk(machine, disk_config, all_disks[1])
      end
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
