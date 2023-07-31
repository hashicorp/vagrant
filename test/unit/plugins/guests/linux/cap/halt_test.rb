# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::Halt" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  context "systemd not enabled" do
    before do
      allow(machine).to receive(:communicate).and_return(comm)
      allow(comm).to receive(:test).and_return(false)
    end

    after do
      comm.verify_expectations!
    end

    describe ".halt" do
      let(:cap) { caps.get(:halt) }

      it "runs the shutdown command" do
        comm.expect_command("shutdown -h now")
        cap.halt(machine)
      end

      it "does not raise an IOError" do
        comm.stub_command("shutdown -h now", raise: IOError)
        expect {
          cap.halt(machine)
        }.to_not raise_error
      end

      it "does not raise a SSHDisconnected" do
        comm.stub_command("shutdown -h now", raise: Vagrant::Errors::SSHDisconnected)
        expect {
          cap.halt(machine)
        }.to_not raise_error
      end
    end

    context "systemd enabled" do
      before do
        allow(machine).to receive(:communicate).and_return(comm)
        allow(comm).to receive(:test).and_return(true)
      end

      after do
        comm.verify_expectations!
      end

      describe ".halt" do
        let(:cap) { caps.get(:halt) }

        it "runs the shutdown command" do
          comm.expect_command("systemctl poweroff")
          cap.halt(machine)
        end
      end
    end
  end
end
