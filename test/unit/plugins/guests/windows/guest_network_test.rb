require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/guests/windows/guest_network")

describe "VagrantPlugins::GuestWindows::GuestNetwork" do

  let(:communicator) { double("communicator") }
  let(:subject) { VagrantPlugins::GuestWindows::GuestNetwork.new(communicator) }

  describe ".is_dhcp_enabled" do
    it "should query the NIC by ordinal index" do
      expect(communicator).to receive(:test).with(
        /.+Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "Index=7 and DHCPEnabled=True"/).
        and_return(true)
      expect(subject.is_dhcp_enabled(7)).to be(true)
    end

    it "should return false for non-DHCP NICs" do
      expect(communicator).to receive(:test).with(
        /.+Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "Index=8 and DHCPEnabled=True"/).
        and_return(false)
      expect(subject.is_dhcp_enabled(8)).to be(false)
    end
  end

  describe ".configure_static_interface" do
    it "should configure IP using netsh" do
      expect(communicator).to receive(:execute).with(
        "netsh interface ip set address \"Local Area Connection 2\" static 192.168.33.10 255.255.255.0").
        and_return(0)
      subject.configure_static_interface(7, "Local Area Connection 2", "192.168.33.10", "255.255.255.0")
    end
  end

  describe ".configure_dhcp_interface" do
    it "should configure DHCP when DHCP is disabled" do
      allow(communicator).to receive(:test).and_return(false) # is DHCP enabled?
      expect(communicator).to receive(:execute).with(
        "netsh interface ip set address \"Local Area Connection 2\" dhcp").
        and_return(0)
      subject.configure_dhcp_interface(7, "Local Area Connection 2")
    end

    it "should not configure DHCP when DHCP is enabled" do
      allow(communicator).to receive(:test).and_return(true) # is DHCP enabled?
      expect(communicator).to_not receive(:execute)
      subject.configure_dhcp_interface(7, "Local Area Connection 2")
    end
  end
end
