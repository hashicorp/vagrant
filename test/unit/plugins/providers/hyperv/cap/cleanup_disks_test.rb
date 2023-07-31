# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
  end

  context "#cleanup_disks" do
    it "returns if there's no data in meta file" do
      subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      expect(subject).not_to receive(:handle_cleanup_disk)
    end

    describe "with disks to clean up" do
      let(:disk_meta_file) { {disk: [{"UUID"=>"1234", "Path"=> "c:\\users\\vagrant\\storage.vhdx", "Name"=>"storage"}], floppy: [], dvd: []} }

      it "calls the cleanup method if a disk_meta file is defined" do
        expect(subject).to receive(:handle_cleanup_disk).
          with(machine, defined_disks, disk_meta_file["disk"]).
          and_return(true)

        subject.cleanup_disks(machine, defined_disks, disk_meta_file)
      end
    end
  end

  context "#handle_cleanup_disk" do
      let(:disk_meta_file) { {disk: [{"UUID"=>"1234", "Path"=> "c:\\users\\vagrant\\storage.vhdx", "Name"=>"storage"}], floppy: [], dvd: []} }
      let(:defined_disks) { [] }
      let(:all_disks) { [{"UUID"=>"1234", "Path"=> "c:\\users\\vagrant\\storage.vhdx", "Name"=>"storage",
                         "ControllerType"=>"IDE", "ControllerNumber"=>1, "ControllerLocation"=>0}] }
      let(:path) { "C:\\Users\\vagrant\\storage.vhdx" }

    it "removes and closes medium from guest" do
      expect(driver).to receive(:list_hdds).and_return(all_disks)
      expect(driver).to receive(:remove_disk).with("IDE", 1, 0, "c:\\users\\vagrant\\storage.vhdx").and_return(true)

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
    end

    it "displays a warning if the disk could not be determined" do
      expect(driver).to receive(:list_hdds).and_return(all_disks)
      expect(File).to receive(:realdirpath).and_return(path)
      expect(File).to receive(:realdirpath).and_return("")
      expect(driver).not_to receive(:remove_disk)
      expect(machine.ui).to receive(:warn).twice

      subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
    end

    describe "when windows paths mix cases" do
      let(:disk_meta_file) { {disk: [{"UUID"=>"1234", "Path"=> "c:\\users\\vagrant\\storage.vhdx", "Name"=>"storage"}], floppy: [], dvd: []} }
      let(:defined_disks) { [] }
      let(:all_disks) { [{"UUID"=>"1234", "Path"=> "C:\\Users\\vagrant\\storage.vhdx", "Name"=>"storage",
                         "ControllerType"=>"IDE", "ControllerNumber"=>1, "ControllerLocation"=>0}] }

      let(:path) { "C:\\Users\\vagrant\\storage.vhdx" }

      it "still removes and closes the medium from the guest" do
        expect(driver).to receive(:list_hdds).and_return(all_disks)
        expect(File).to receive(:realdirpath).twice.and_return(path)
        expect(driver).to receive(:remove_disk).with("IDE", 1, 0, path).and_return(true)

        subject.handle_cleanup_disk(machine, defined_disks, disk_meta_file[:disk])
      end
    end
  end
end
