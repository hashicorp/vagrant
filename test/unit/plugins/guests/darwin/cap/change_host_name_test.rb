# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
      .get(:change_host_name)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:name) { "banana-rama.example.com" }
  let(:basename) { "banana-rama" }
  let(:networks) {}

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    context "minimal network config" do
      let(:networks) { [
        [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]
      ] }

      it "sets the hostname" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 1)
        described_class.change_host_name(machine, name)
        expect(comm.received_commands[1]).to match(/scutil --set ComputerName '#{name}'/)
        expect(comm.received_commands[1]).to match(/scutil --set HostName '#{name}'/)
        expect(comm.received_commands[1]).to match(/scutil --set LocalHostName '#{basename}'/)
        expect(comm.received_commands[1]).to match(/hostname 'banana-rama.example.com'/)
        expect(described_class).to_not receive(:add_hostname_to_loopback_interface)
      end

      it "does not change the hostname if already set" do
        comm.stub_command("hostname -f | grep '^#{name}$'", exit_code: 0)
        described_class.change_host_name(machine, name)
        expect(comm).to_not receive(:sudo).with(/scutil --set ComputerName '#{name}/)
        expect(described_class).to_not receive(:add_hostname_to_loopback_interface)
      end
    end

    context "multiple networks configured with hostname" do 
      it "adds a new entry only for the hostname" do 
        networks = [
          [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
          [:public_network, {:ip=>"192.168.0.1", :hostname=>true, :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
          [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
        expect(described_class).to receive(:replace_host)
        expect(described_class).to_not receive(:add_hostname_to_loopback_interface)
        described_class.change_host_name(machine, name)
      end

      it "appends an entry to the loopback interface" do 
        networks = [
          [:forwarded_port, {:guest=>22, :host=>2222, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}],
          [:public_network, {:ip=>"192.168.0.1", :protocol=>"tcp", :id=>"93a4ad88-0774-4127-a161-ceb715ff372f"}],
          [:public_network, {:ip=>"192.168.0.2", :protocol=>"tcp", :id=>"5aebe848-7d85-4425-8911-c2003d924120"}]
        ]
        allow(machine).to receive_message_chain(:config, :vm, :networks).and_return(networks)
        expect(described_class).to_not receive(:replace_host)
        expect(described_class).to receive(:add_hostname_to_loopback_interface).once
        described_class.change_host_name(machine, name)
      end
    end
  end
end
