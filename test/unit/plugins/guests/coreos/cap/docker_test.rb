# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"

describe "VagrantPlugins::GuestCoreOS::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestCoreOS::Plugin
      .components
      .guest_capabilities[:coreos]
      .get(:docker_daemon_running)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".docker_daemon_running" do
    it "checks /run/docker/sock" do
      described_class.docker_daemon_running(machine)
      expect(comm.received_commands[0]).to eq("test -S /run/docker.sock")
    end
  end
end
