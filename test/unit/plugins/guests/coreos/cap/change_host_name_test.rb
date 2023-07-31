# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestCoreOS::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestCoreOS::Plugin
      .components
      .guest_capabilities[:coreos]
      .get(:change_host_name)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    let(:name) { "banana-rama.example.com" }
    let(:has_cloudinit) { false }

    before do
      allow(described_class).to receive(:systemd_unit_file?).
        with(anything, /cloudinit/).and_return(has_cloudinit)
    end

    context "with systemd cloud-init" do
      let(:has_cloudinit) { true }

      it "should upload cloudinit configuration file" do
        expect(comm).to receive(:upload)
        described_class.change_host_name(machine, name)
      end

      it "should set hostname in configuration file" do
        expect(comm).to receive(:upload) do |src, dst|
          contents = File.read(src)
          expect(contents).to include(name)
        end
        described_class.change_host_name(machine, name)
      end

      it "should start the cloudinit service" do
        expect(comm).to receive(:sudo).with(/systemctl start system-cloudinit/)
        described_class.change_host_name(machine, name)
      end
    end

    context "without systemd cloud-init" do
      it "sets the hostname" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
        comm.expect_command("hostname 'banana-rama'")
        described_class.change_host_name(machine, name)
      end

      it "does not change the hostname if already set" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
        described_class.change_host_name(machine, name)
        expect(comm.received_commands.size).to eq(1)
      end
    end
  end
end
