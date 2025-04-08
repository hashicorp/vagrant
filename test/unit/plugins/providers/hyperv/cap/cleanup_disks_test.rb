# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"
require Vagrant.source_root.join("plugins/providers/hyperv/cap/cleanup_disks")

describe VagrantPlugins::HyperV::Cap::CleanupDisks do
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

  context "#cleanup_disks" do
    it "returns if there's no data in meta file" do
      subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      expect(subject).not_to receive(:handle_cleanup_disk)
    end

    describe "with disks to clean up" do
      let(:disk_meta_file) do
        {
          "disk" => [
            {
              "UUID" => "1234",
              "Path" => "c:\\users\\vagrant\\storage.vhdx",
              "Name" => "storage"
            }
          ],
          "floppy" => [],
          "dvd" => []
        }
      end

      before { allow(driver).to receive(:read_scsi_controllers).and_return([]) }

      it "calls the cleanup method if a disk_meta file is defined" do
        expect(subject).to receive(:handle_cleanup_disk).
          with(machine, defined_disks, disk_meta_file["disk"]).
          and_return(true)

        subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      end

      context "with dvd to clean up" do
        let(:disk_meta_file) do
          {
            "disk" => [],
            "floppy" => [],
            "dvd" => [
              {
                "Path" => "test.iso"
              }
            ]
          }

          it "calls the cleamup method if a disk_meta file is defined" do
            expect(subject).to receive(:handle_cleanup_dvd).
              with(machine, defined_disks, disk_meta_file["dvd"]).
              and_return(true)

            subject.cleanup_disks(machine, defined_disks, disk_meta_file)
          end
        end

      end
    end
  end

  context "handle_cleanup_dvd" do
    let(:disk_meta_file) do
      {
        "disk" => [],
        "floppy" => [],
        "dvd" => []
      }
    end
    let(:scsi_controllers) do
      [
        {
          "ControllerNumber" => 0,
          "Name" => "SCSI Controller",
          "Drives" => drives
        }
      ]
    end
    let(:drives) do
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
    let(:defined_disks) { [] }

    before do
      allow(driver).to receive(:read_scsi_controllers).and_return(scsi_controllers)
    end

    it "should not remove disk" do
      expect(driver).not_to receive(:detach_dvd)

      subject.handle_cleanup_dvd(machine, defined_disks, disk_meta_file["dvd"])
    end

    context "when disk is defined in meta file" do
      let(:disk_meta_file) do
        {
          "disk" => [],
          "floppy" => [],
          "dvd" => [
            "Path" => "test.iso",
            "ControllerLocation" => 1,
            "ControllerNumber" => 0,
            "ControllerType" => 1
          ]
        }
      end

      it "should remove the disk" do
        expect(driver).to receive(:detach_dvd).with(1, 0)

        subject.handle_cleanup_dvd(machine, defined_disks, disk_meta_file["dvd"])
      end

      context "when disk is defined in defined disks" do
        let(:defined_disks) do
          [
            double("dvd", name: "test-dvd", type: :dvd, file: "test.iso")
          ]
        end

        it "should not remove disk" do
          expect(driver).not_to receive(:detach_dvd)

          subject.handle_cleanup_dvd(machine, defined_disks, disk_meta_file["dvd"])
        end
      end
    end
  end

  context "#handle_cleanup_disk" do
    let(:disk_meta_file) do
      {
        "disk" => [
          {
            "UUID" => "1234",
            "Path" => "c:\\users\\vagrant\\storage.vhdx",
            "Name" => "storage"
          }
        ],
        "floppy" => [],
        "dvd" => []
      }
    end
    let(:defined_disks) { [] }
    let(:all_disks) do
      [
        {
          "UUID" => "1234",
          "Path" => "c:\\users\\vagrant\\storage.vhdx",
          "Name"=>"storage",
          "ControllerType" => "IDE",
          "ControllerNumber" => 1,
          "ControllerLocation" => 0
        }
      ]
    end
    let(:path) { "C:\\Users\\vagrant\\storage.vhdx" }

    it "removes and closes medium from guest" do
      expect(driver).to receive(:list_hdds).and_return(all_disks)
      expect(driver).to receive(:remove_disk).with("IDE", 1, 0, "c:\\users\\vagrant\\storage.vhdx").and_return(true)

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
    end

    it "displays a warning if the disk could not be determined" do
      expect(driver).to receive(:list_hdds).and_return(all_disks)
      expect(File).to receive(:realdirpath).and_return(path)
      expect(File).to receive(:realdirpath).and_return("")
      expect(driver).not_to receive(:remove_disk)
      expect(machine.ui).to receive(:warn).twice

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
    end

    describe "when windows paths mix cases" do
      let(:disk_meta_file) do
        {
          "disk" => [
            {
              "UUID" => "1234",
              "Path" => "c:\\users\\vagrant\\storage.vhdx",
              "Name" => "storage"
            }
          ],
          "floppy" => [],
          "dvd" => []
        }
      end
      let(:defined_disks) { [] }
      let(:all_disks) do
        [
          {
            "UUID" => "1234",
            "Path" => "C:\\Users\\vagrant\\storage.vhdx",
            "Name" => "storage",
            "ControllerType" => "IDE",
            "ControllerNumber" => 1,
            "ControllerLocation" => 0
          }
        ]
      end

      let(:path) { "C:\\Users\\vagrant\\storage.vhdx" }

      it "still removes and closes the medium from the guest" do
        expect(driver).to receive(:list_hdds).and_return(all_disks)
        expect(File).to receive(:realdirpath).twice.and_return(path)
        expect(driver).to receive(:remove_disk).with("IDE", 1, 0, path).and_return(true)

        subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
      end
    end
  end
end
