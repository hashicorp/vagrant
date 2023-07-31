# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:cap) { caps.get(:change_host_name) }
  let(:name) { "banana-rama.example.com" }
  let(:basename) { "banana-rama" }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(cap).to receive(:hostnamectl?).and_return(true)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    context "minimal network config" do 
      let(:networks) { [
        [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]
      ] }

      before do 
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
      end

      it "sets the hostname" do
        comm.stub_command('test "$(hostnamectl --static status)" = "#{basename}"', exit_code: 1)

        cap.change_host_name(machine, name)
        expect(comm.received_commands[2]).to match(/echo #{name} > \/etc\/HOSTNAME/)
        expect(comm.received_commands[2]).to match(/hostnamectl set-hostname '#{basename}'/)
      end

      it "does not change the hostname if already set" do
        comm.stub_command('test "$(hostnamectl --static status)" = "#{basename}"', exit_code: 0)

        cap.change_host_name(machine, name)
        expect(comm.received_commands.size).to eq(3)
      end

      context "hostnamectl is not present" do 
        before do
          allow(cap).to receive(:hostnamectl?).and_return(false)
        end
  
        it "sets the hostname" do
          comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
  
          cap.change_host_name(machine, name)
          expect(comm.received_commands[2]).to match(/echo #{name} > \/etc\/HOSTNAME/)
          expect(comm.received_commands[2]).to match(/hostname '#{basename}'/)
        end
    end
    end
  end
end
