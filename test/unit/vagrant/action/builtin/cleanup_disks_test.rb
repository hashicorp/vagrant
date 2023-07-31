# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::CleanupDisks do
  let(:app) { lambda { |env| } }
  let(:vm) { double("vm") }
  let(:config) { double("config", vm: vm) }
  let(:provider) { double("provider") }
  let(:machine) { double("machine", config: config, provider: provider, name: "machine",
                         provider_name: "provider", data_dir: Pathname.new("/fake/dir")) }
  let(:env) { { ui: ui, machine: machine} }

  let(:disks) { [double("disk")] }

  let(:ui)  { Vagrant::UI::Silent.new }

  let(:disk_meta_file) { {disk: [{uuid: "123456789", name: "storage"}], floppy: [], dvd: []} }

  describe "#call" do
    it "calls configure_disks if disk config present" do
      allow(vm).to receive(:disks).and_return(disks)
      allow(machine).to receive(:disks).and_return(disks)
      allow(machine.provider).to receive(:capability?).with(:cleanup_disks).and_return(true)
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(subject).to receive(:read_disk_metadata).with(machine).and_return(disk_meta_file)
      expect(machine.provider).to receive(:capability).
        with(:cleanup_disks, disks, disk_meta_file)

      subject.call(env)
    end

    it "continues on if no disk config present" do
      allow(vm).to receive(:disks).and_return([])
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).not_to receive(:capability).with(:cleanup_disks, disks)

      subject.call(env)
    end

    it "prints a warning if disk config capability is unsupported" do
      allow(vm).to receive(:disks).and_return(disks)
      allow(machine.provider).to receive(:capability?).with(:cleanup_disks).and_return(false)
      subject = described_class.new(app, env)
      expect(subject).to receive(:read_disk_metadata).with(machine).and_return(disk_meta_file)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).not_to receive(:capability).with(:cleanup_disks, disks)
      expect(ui).to receive(:warn)

      subject.call(env)
    end
  end
end
