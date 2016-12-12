# Copyright (c) 2015 VMware, Inc. All Rights Reserved.

require_relative "../../../../base"

describe "VagrantPlugins::GuestPhoton::Cap:Docker" do
  let(:caps) do
    VagrantPlugins::GuestPhoton::Plugin
      .components
      .guest_capabilities[:photon]
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
    let(:cap) { caps.get(:docker_daemon_running) }

    it "installs rsync" do
      comm.expect_command("test -S /run/docker.sock")
      cap.docker_daemon_running(machine)
    end
  end
end
