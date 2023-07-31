# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)
require 'vagrant/util/guest_hosts'

describe "Vagrant::Util::GuestHosts" do
  include_context "unit"

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  describe "Linux" do
    subject{ Class.new { extend Vagrant::Util::GuestHosts::Linux } }
    
    it "can add replace hostname" do
      subject.replace_host(comm, "test.end", "192.186.4.2")
      expect(comm.received_commands[0]).to match(/sed -i '\/test.end\/d' \/etc\/hosts/)
    end

    it "can add hostname to loopback interface" do
      subject.add_hostname_to_loopback_interface(comm, "test.end", 4)
      expect(comm.received_commands[0]).to match(/for i in 1 2 3 4; do/)
      expect(comm.received_commands[0]).to match(/echo \"127.0.\${i}.1 test.end test\" >> \/etc\/hosts/)
    end
  end

  describe "BSD" do
    subject{ Class.new { extend Vagrant::Util::GuestHosts::BSD } }

    it "can add replace hostname" do
      subject.replace_host(comm, "test.end", "192.186.4.2")
      expect(comm.received_commands[0]).to match(/sed -i.bak '\/test.end\/d' \/etc\/hosts/)
    end

    it "can add hostname to loopback interface" do
      subject.add_hostname_to_loopback_interface(comm, "test.end", 4)
      expect(comm.received_commands[0]).to match(/for i in 1 2 3 4; do/)
      expect(comm.received_commands[0]).to match(/echo \"127.0.\${i}.1 test.end test\" >> \/etc\/hosts/)
    end
  end
end
