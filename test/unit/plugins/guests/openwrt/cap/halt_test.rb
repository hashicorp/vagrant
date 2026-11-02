# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestOpenWrt::Cap::Halt" do
  let(:plugin) { VagrantPlugins::GuestOpenWrt::Plugin.components.guest_capabilities[:openwrt].get(:halt) }
  let(:machine) { double("machine") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:shutdown_command){ "halt" }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  after do
    communicator.verify_expectations!
  end

  describe ".halt" do
    it "sends a shutdown signal" do
      communicator.expect_command(shutdown_command)
      plugin.halt(machine)
    end

    it "ignores an IOError" do
      communicator.stub_command(shutdown_command, raise: IOError)
      expect {
        plugin.halt(machine)
      }.to_not raise_error
    end

    it "ignores a Vagrant::Errors::SSHDisconnected" do
      communicator.stub_command(shutdown_command, raise: Vagrant::Errors::SSHDisconnected)
      expect {
        plugin.halt(machine)
      }.to_not raise_error
    end
  end
end
