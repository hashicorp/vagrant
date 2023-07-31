# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestHaiku::Cap::RSync" do
  let(:caps) do
    VagrantPlugins::GuestHaiku::Plugin
      .components
      .guest_capabilities[:haiku]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".rsync_install" do
    let(:cap) { caps.get(:rsync_install) }

    it "installs rsync" do
      comm.expect_command("pkgman install -y rsync")
      cap.rsync_install(machine)
    end
  end

  describe ".rsync_installed" do
    let(:cap) { caps.get(:rsync_installed) }

    it "checks if rsync is installed" do
      comm.expect_command("test -f /bin/rsync")
      cap.rsync_installed(machine)
    end
  end

  describe ".rsync_command" do
    let(:cap) { caps.get(:rsync_command) }

    it "defaults to 'rsync -zz'" do
      expect(cap.rsync_command(machine)).to eq("rsync -zz")
    end
  end
end
