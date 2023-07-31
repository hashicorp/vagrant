# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::SMB" do
  let(:described_class) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
      .get(:smb_install)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".smb_install" do
    it "installs smb when /sbin/mount.cifs does not exist" do
      comm.stub_command("test -f /sbin/mount.cifs", exit_code: 1)
      described_class.smb_install(machine)

      expect(comm.received_commands[1]).to match(/if command -v dnf; then/)
      expect(comm.received_commands[1]).to match(/dnf -y install cifs-utils/)
    end

    it "does not install smb when /sbin/mount.cifs exists" do
      comm.stub_command("test -f /sbin/mount.cifs", exit_code: 0)
      described_class.smb_install(machine)

      expect(comm.received_commands.join("")).to_not match(/update/)
    end
  end
end
