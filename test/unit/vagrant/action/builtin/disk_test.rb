# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Disk do
  let(:app) { lambda { |env| } }
  let(:vm) { double("vm") }
  let(:config) { double("config", vm: vm) }
  let(:provider) { double("provider") }
  let(:machine) { double("machine", config: config, provider: provider,
                         provider_name: "provider", data_dir: Pathname.new("/fake/dir")) }
  let(:env) { { ui: ui, machine: machine} }

  let(:disks) { [double("disk")] }

  let(:ui)  { Vagrant::UI::Silent.new }

  let(:disk_data) { {disk: [{uuid: "123456789", name: "storage"}], floppy: [], dvd: []} }

  describe "#call" do
    it "calls configure_disks if disk config present" do
      allow(vm).to receive(:disks).and_return(disks)
      allow(machine).to receive(:disks).and_return(disks)
      allow(machine.provider).to receive(:capability?).with(:configure_disks).and_return(true)
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).to receive(:capability).
        with(:configure_disks, disks).and_return(disk_data)

      expect(subject).to receive(:write_disk_metadata).and_return(true)

      subject.call(env)
    end

    it "continues on if no disk config present" do
      allow(vm).to receive(:disks).and_return([])
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).not_to receive(:capability).with(:configure_disks, disks)

      expect(subject).not_to receive(:write_disk_metadata)

      subject.call(env)
    end

    it "prints a warning if disk config capability is unsupported" do
      allow(vm).to receive(:disks).and_return(disks)
      allow(machine.provider).to receive(:capability?).with(:configure_disks).and_return(false)
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).not_to receive(:capability).with(:configure_disks, disks)
      expect(ui).to receive(:warn)

      subject.call(env)
    end

    it "writes down a disk_meta file if disks are configured" do
      subject = described_class.new(app, env)

      expect(File).to receive(:open).with("/fake/dir/disk_meta", "w+").and_return(true)

      subject.write_disk_metadata(machine, disk_data)
    end
  end
end
