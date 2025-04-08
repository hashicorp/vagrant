# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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

  let(:defined_disks) do
    [
      double("disk", name: "vagrant_primary", size: "5GB", primary: true, type: :disk),
      double("disk", name: "disk-0", size: "5GB", primary: false, type: :disk),
      double("disk", name: "disk-1", size: "5GB", primary: false, type: :disk),
      double("disk", name: "disk-2", size: "5GB", primary: false, type: :disk)
    ]
  end

  let(:subject) { described_class }

  let(:all_disks) do
    [
      {
        "UUID"=>"12345",
        "Path"=>"C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
        "ControllerLocation"=>0,
        "ControllerNumber"=>0
      },
      {
        "UUID"=>"67890",
        "Name"=>"disk-0",
        "Path"=>"C:/Users/vagrant/disks/disk-0.vhdx",
        "ControllerLocation"=>1,
        "ControllerNumber"=>0
      },
      {
        "UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
        "Path"=>"C:/Users/vagrant/disks/disk-1.vhdx",
        "Name"=>"disk-1",
        "ControllerLocation"=>2,
        "ControllerNumber"=>0
      }
    ]
  end

  context "#configure_disks" do
    let(:dsk_data) do
      {
        "UUID"=>"1234",
        "Name"=>"disk",
        "Path"=> "C:/Users/vagrant/storage.vhdx"
      }
    end

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

    context "with dvd" do
      before do
        defined_disks.push(
          double("dvd", name: "test-dvd", type: :dvd, file: "test.iso")
        )
      end

      it "should configure the dvd disk" do
        allow(driver).to receive(:list_hdds).and_return([])
        allow(subject).to receive(:handle_configure_disk).and_return({})
        expect(subject).to receive(:handle_configure_dvd).and_return({})

        subject.configure_disks(machine, defined_disks)
      end
    end
  end

  context "#get_current_disk" do
    it "gets primary disk uuid if disk to configure is primary" do
      expect(driver).to receive(:get_disk).with(all_disks.first["Path"]).and_return(all_disks.first)
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

    context "when primary disk is not located at 0 0" do
      let(:all_disks) do
        [
          {
            "UUID"=>"12345",
            "Path"=>"C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
            "ControllerLocation"=>1,
            "ControllerNumber"=>0
          },
          {
            "UUID"=>"67890",
            "Name"=>"disk-0",
            "Path"=>"C:/Users/vagrant/disks/disk-0.vhdx",
            "ControllerLocation"=>2,
            "ControllerNumber"=>0
          },
          {
            "UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
            "Path"=>"C:/Users/vagrant/disks/disk-1.vhdx",
            "Name"=>"disk-1",
            "ControllerLocation"=>3,
            "ControllerNumber"=>0
          }
        ]
      end

      it "should return the primary disk" do
        expect(driver).to receive(:get_disk).with(all_disks.first["Path"]).and_return(all_disks.first)
        primary_disk = subject.get_current_disk(machine, defined_disks.first, all_disks)
        expect(primary_disk).to eq(all_disks.first)
      end

      context "when disks are unsorted" do
        let(:all_disks) do
          [
            {
              "UUID"=>"67890",
              "Name"=>"disk-0",
              "Path"=>"C:/Users/vagrant/disks/disk-0.vhdx",
              "ControllerLocation"=>2,
              "ControllerNumber"=>0
            },
            {
              "UUID"=>"12345",
              "Path"=>"C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
              "ControllerLocation"=>1,
              "ControllerNumber"=>0
            },
            {
              "UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
              "Path"=>"C:/Users/vagrant/disks/disk-1.vhdx",
              "Name"=>"disk-1",
              "ControllerLocation"=>3,
              "ControllerNumber"=>0
            }
          ]
        end

        it "should return the primary disk" do
          expect(driver).to receive(:get_disk).with(all_disks[1]["Path"]).and_return(all_disks[1])
          primary_disk = subject.get_current_disk(machine, defined_disks.first, all_disks)
          expect(primary_disk).to eq(all_disks[1])
        end
      end
    end
  end

  context "#handle_configure_dvd" do
    let(:scsi_controllers_current) do
      [
        {
          "ControllerNumber" => 0,
          "Name" => "SCSI Controller",
          "Drives" => drives_current
        }
      ]
    end
    let(:drives_current) { [] }
    let(:scsi_controllers_updated) do
      [
        {
          "ControllerNumber" => 0,
          "Name" => "SCSI Controller",
          "Drives" => drives_updated
        }
      ]
    end
    let(:drives_updated) do
      [
        {
          "DvdMediaType" => 1,
          "Path" => "test.iso",
          "ControllerLocation" => 1,
          "ControllerNumber" => 0,
          "ControllerType" => 1
        }
      ]
    end

    let(:defined_disk) do
      double("dvd", name: "test-dvd", type: :dvd, file: "test.iso")
    end

    it "should add disk to guest" do
      expect(driver).to receive(:read_scsi_controllers).and_return(scsi_controllers_current)
      expect(driver).to receive(:read_scsi_controllers).and_return(scsi_controllers_updated)
      expect(driver).to receive(:attach_dvd).with(/test.iso$/)

      subject.handle_configure_dvd(machine, defined_disk)
    end

    context "when disk is already attached" do
      let(:drives_current) do
        [
          {
            "DvdMediaType" => 1,
            "Path" => "test.iso",
            "ControllerLocation" => 1,
            "ControllerNumber" => 0,
            "ControllerType" => 1
          }
        ]
      end

      it "should not add disk to guest" do
        expect(driver).to receive(:read_scsi_controllers).and_return(scsi_controllers_current)
        expect(driver).not_to receive(:attach_dvd)

        subject.handle_configure_dvd(machine, defined_disk)
      end

      context "when additional disk is defined" do
        let(:defined_disk) do
          double("dvd", name: "other-dvd", type: :dvd, file: "other-test.iso")
        end

        let(:drives_updated) do
          [
            {
              "DvdMediaType" => 1,
              "Path" => "test.iso",
              "ControllerLocation" => 1,
              "ControllerNumber" => 0,
              "ControllerType" => 1
            },
            {
              "DvdMediaType" => 1,
              "Path" => "other-test.iso",
              "ControllerLocation" => 2,
              "ControllerNumber" => 0,
              "ControllerType" => 1
            }
          ]
        end


        it "should add disk to guest" do
          expect(driver).to receive(:read_scsi_controllers).and_return(scsi_controllers_current)
          expect(driver).to receive(:read_scsi_controllers).and_return(scsi_controllers_updated)
          expect(driver).to receive(:attach_dvd).with(/other-test.iso$/)

          subject.handle_configure_dvd(machine, defined_disk)
        end
      end
    end
  end

  context "#handle_configure_disk" do
    describe "when creating a new disk" do
      let(:all_disks) do
        [
          {
            "UUID"=>"12345",
            "Path"=>"C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
            "ControllerLocation"=>0,
            "ControllerNumber"=>0
          }
        ]
      end

      let(:disk_meta) do
        {
          "UUID" => "12345",
          "Name" => "vagrant_primary",
          "Path" => "C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx"
        }
      end

      it "creates a new disk if it doesn't yet exist" do
        expect(subject).to receive(:create_disk).with(machine, defined_disks[1])
          .and_return(disk_meta)

        subject.handle_configure_disk(machine, defined_disks[1], all_disks)
      end
    end

    describe "when a disk needs to be resized" do
      let(:all_disks) do
        [
          {"UUID"=>"12345",
           "Path"=>"C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
           "ControllerLocation"=>0,
           "ControllerNumber"=>0
          },
          {
            "UUID"=>"67890",
            "Name"=>"disk-0",
            "Path"=>"C:/Users/vagrant/disks/disk-0.vhdx",
            "ControllerLocation"=>1,
            "ControllerNumber"=>0
          },
          {
            "UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
            "Path"=>"C:/Users/vagrant/disks/disk-1.vhdx",
            "Name"=>"disk-1",
            "ControllerLocation"=>2,
            "ControllerNumber"=>0
          }
        ]
      end

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
      let(:all_disks) do
        [
          {
            "UUID"=>"12345",
            "Path"=>"C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
            "ControllerLocation"=>0,
            "ControllerNumber"=>0
          },
          {
            "UUID"=>"67890",
            "Name"=>"disk-0",
            "Path"=>"C:/Users/vagrant/disks/disk-0.vhdx",
            "ControllerLocation"=>1,
            "ControllerNumber"=>0
          },
          {
            "UUID"=>"324bbb53-d5ad-45f8-9bfa-1f2468b199a8",
            "Path"=>"C:/Users/vagrant/disks/disk-1.vhdx",
            "Name"=>"disk-1",
            "ControllerLocation"=>2,
            "ControllerNumber"=>0
          }
        ]
      end

      it "does nothing if all disks are properly configured" do
        expect(subject).to receive(:get_current_disk).
          with(machine, defined_disks[1], all_disks).and_return(all_disks[1])

        expect(subject).to receive(:compare_disk_size).
          with(machine, defined_disks[1], all_disks[1]).and_return(false)

        subject.handle_configure_disk(machine, defined_disks[1], all_disks)
      end
    end
  end

  context "#compare_disk_size" do
    let(:disk_config_small) do
      double("disk",
        name: "disk-0",
        size: 41824.0,
        primary: false,
        type: :disk
      )
    end
    let(:disk_config_large) do
      double("disk",
        name: "disk-0",
        size: 123568719476736.0,
        primary: false,
        type: :disk
      )
    end

    let(:disk_large) do
      [
        {
          "UUID" => "12345",
          "Path" => "C:/Users/vagrant/disks/ubuntu-18.04-amd64-disk001.vhdx",
          "ControllerLocation" => 0,
          "ControllerNumber" => 0
        }
      ]
    end

    let(:disk_small) do
      {
        "UUID" => "67890",
        "Path" => "C:/Users/vagrant/disks/small_disk.vhd",
        "Size" => 1073741824.0,
        "ControllerLocation" => 1,
        "ControllerNumber" => 0
      }
    end

    it "shows a warning if user attempts to shrink size of a vhd disk" do
      expect(machine.ui).to receive(:warn)
      expect(driver).to receive(:get_disk).with(all_disks[1]["Path"]).and_return(disk_small)

      expect(subject.compare_disk_size(machine, disk_config_small, all_disks[1])).to be_falsey
    end

    it "returns true if requested size is bigger than current size" do
      expect(driver).to receive(:get_disk).with(all_disks[2]["Path"]).and_return(disk_small)
      expect(subject.compare_disk_size(machine, disk_config_large, all_disks[2])).to be_truthy
    end
  end

  context "#create_disk" do
    let(:disk_provider_config) { {} }
    let(:disk_config) do
      double("disk",
        name: "disk-0",
        size: 1073741824.0,
        primary: false,
        type: :disk,
        disk_ext: "vhdx",
        provider_config: disk_provider_config,
        file: nil
      )
    end

    let(:disk_file) { "C:/Users/vagrant/disks/Virtual Hard Disks/disk-0.vhdx" }

    let(:data_dir) { Pathname.new("C:/Users/vagrant/disks") }

    let(:disk) do
      {
        "DiskIdentifier" => "12345",
        "Path" => "C:/Users/vagrant/disks/Virtual Hard Disks/disk-0.vhdx",
        "ControllerLocation" => 1,
        "ControllerNumber" => 0
      }
    end

    it "creates a disk and attaches it to a guest" do
      expect(machine).to receive(:data_dir).and_return(data_dir)
      expect(driver).to receive(:create_disk).with(disk_file, disk_config.size)
      expect(driver).to receive(:get_disk).with(disk_file).and_return(disk)

      expect(driver).to receive(:attach_disk).with(disk_file)

      subject.create_disk(machine, disk_config)
    end
  end

  context "#convert_size_vars!" do
    let(:disk_provider_config) do
      {
        BlockSizeBytes: "128MB",
        LogicalSectorSizeBytes: 512,
        PhysicalSectorSizeBytes: 4096
      }
    end

    it "converts certain powershell arguments into something usable" do
      updated_config = subject.convert_size_vars!(disk_provider_config)

      expect(updated_config[:BlockSizeBytes]).to eq(134217728)
      expect(updated_config[:LogicalSectorSizeBytes]).to eq(512)
      expect(updated_config[:PhysicalSectorSizeBytes]).to eq(4096)
    end
  end

  context "#resize_disk" do
    let(:disk_config) do
      double("disk",
        name: "disk-0",
        size: 1073741824.0,
        primary: false,
        type: :disk,
        disk_ext: "vhdx",
        provider_config: nil,
        file: nil
      )
    end

    let(:disk) do
      {
        "DiskIdentifier" => "12345",
        "Path" => "C:/Users/vagrant/disks/disk-0.vhdx",
        "ControllerLocation" => 1,
        "ControllerNumber" => 0
      }
    end

    let(:disk_file) { "C:/Users/vagrant/disks/disk-0.vhdx" }

    it "resizes the disk" do
      expect(driver).to receive(:get_disk).with(disk_file).and_return(disk)
      expect(driver).to receive(:resize_disk).with(disk_file, disk_config.size.to_i).and_return(true)

      subject.resize_disk(machine, disk_config, all_disks[1])
    end
  end
end

val =<<-EOF
{
    "ControllerNumber":  0,
    "IsTemplate":  false,
    "Drives":  [
                   {
                       "Path":  "C:\\Users\\vagrant\\project\\.vagrant\\machines\\default\\hyperv\\Virtual Hard Disks\\ubuntu-18.04-amd64.vhdx",
                       "DiskNumber":  null,
                       "MaximumIOPS":  0,
                       "MinimumIOPS":  0,
                       "QoSPolicyID":  "00000000-0000-0000-0000-000000000000",
                       "SupportPersistentReservations":  false,
                       "WriteHardeningMethod":  0,
                       "ControllerLocation":  0,
                       "ControllerNumber":  0,
                       "ControllerType":  1,
                       "Name":  "Hard Drive on SCSI controller number 0 at location 0",
                       "PoolName":  "Primordial",
                       "Id":  "Microsoft:6F225311-B793-49CF-98A3-0A32108E49BB\\6AEC67E1-3135-401C-BB23-9FE1C4E34560\\0\\0\\D",
                       "VMId":  "6f225311-b793-49cf-98a3-0a32108e49bb",
                       "VMName":  "project_default_1744059721263_2993",
                       "VMSnapshotId":  "00000000-0000-0000-0000-000000000000",
                       "VMSnapshotName":  "",
                       "CimSession":  {
                                          "ComputerName":  null,
                                          "InstanceId":  "899e8c1f-5c4f-4ba4-86a4-f72dc887885f"
                                      },
                       "ComputerName":  "DESKTOP-GICAJ17",
                       "IsDeleted":  false
                   },
                   {
                       "DvdMediaType":  1,
                       "Path":  "C:\\Users\\Vagrant\\deb2.iso",
                       "ControllerLocation":  2,
                       "ControllerNumber":  0,
                       "ControllerType":  1,
                       "Name":  "DVD Drive on SCSI controller number 0 at location 2",
                       "PoolName":  "Primordial",
                       "Id":  "Microsoft:6F225311-B793-49CF-98A3-0A32108E49BB\\6AEC67E1-3135-401C-BB23-9FE1C4E34560\\0\\2\\D",
                       "VMId":  "6f225311-b793-49cf-98a3-0a32108e49bb",
                       "VMName":  "project_default_1744059721263_2993",
                       "VMSnapshotId":  "00000000-0000-0000-0000-000000000000",
                       "VMSnapshotName":  "",
                       "CimSession":  {
                                          "ComputerName":  null,
                                          "InstanceId":  "899e8c1f-5c4f-4ba4-86a4-f72dc887885f"
                                      },
                       "ComputerName":  "DESKTOP-GICAJ17",
                       "IsDeleted":  false
                   }
               ],
    "Name":  "SCSI Controller",
    "Id":  "Microsoft:6F225311-B793-49CF-98A3-0A32108E49BB\\6AEC67E1-3135-401C-BB23-9FE1C4E34560\\0",
    "VMId":  "6f225311-b793-49cf-98a3-0a32108e49bb",
    "VMName":  "project_default_1744059721263_2993",
    "VMSnapshotId":  "00000000-0000-0000-0000-000000000000",
    "VMSnapshotName":  "",
    "CimSession":  {
                       "ComputerName":  null,
                       "InstanceId":  "899e8c1f-5c4f-4ba4-86a4-f72dc887885f"
                   },
    "ComputerName":  "DESKTOP-GICAJ17",
    "IsDeleted":  false,
    "VMCheckpointId":  "00000000-0000-0000-0000-000000000000",
    "VMCheckpointName":  ""
}
EOF
