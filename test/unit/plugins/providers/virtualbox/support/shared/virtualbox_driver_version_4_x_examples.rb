shared_examples "a version 4.x virtualbox driver" do |options|
  before do
    raise ArgumentError, "Need virtualbox context to use these shared examples." if !(defined? vbox_context)
  end

  describe "read_dhcp_servers" do
    before {
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "list", "dhcpservers", an_instance_of(Hash)).
        and_return(subprocess_result(stdout: output))
    }

    context "with empty output" do
      let(:output) { "" }

      it "returns an empty list" do
        expect(subject.read_dhcp_servers).to eq([])
      end
    end

    context "with a single dhcp server" do
      let(:output) {
        <<-OUTPUT.gsub(/^ */, '')
          NetworkName:    HostInterfaceNetworking-vboxnet0
          IP:             172.28.128.2
          NetworkMask:    255.255.255.0
          lowerIPAddress: 172.28.128.3
          upperIPAddress: 172.28.128.254
          Enabled:        Yes

        OUTPUT
      }


      it "returns a list with one entry describing that server" do
        expect(subject.read_dhcp_servers).to eq([{
          network_name: 'HostInterfaceNetworking-vboxnet0',
          network:      'vboxnet0',
          ip:           '172.28.128.2',
          netmask:      '255.255.255.0',
          lower:        '172.28.128.3',
          upper:        '172.28.128.254',
        }])
      end
    end

    context "with a multiple dhcp servers" do
      let(:output) {
        <<-OUTPUT.gsub(/^ */, '')
          NetworkName:    HostInterfaceNetworking-vboxnet0
          IP:             172.28.128.2
          NetworkMask:    255.255.255.0
          lowerIPAddress: 172.28.128.3
          upperIPAddress: 172.28.128.254
          Enabled:        Yes

          NetworkName:    HostInterfaceNetworking-vboxnet1
          IP:             10.0.0.2
          NetworkMask:    255.255.255.0
          lowerIPAddress: 10.0.0.3
          upperIPAddress: 10.0.0.254
          Enabled:        Yes
        OUTPUT
      }


      it "returns a list with one entry for each server" do
        expect(subject.read_dhcp_servers).to eq([
          {network_name: 'HostInterfaceNetworking-vboxnet0', network: 'vboxnet0', ip: '172.28.128.2', netmask: '255.255.255.0', lower: '172.28.128.3', upper: '172.28.128.254'},
          {network_name: 'HostInterfaceNetworking-vboxnet1', network: 'vboxnet1', ip: '10.0.0.2', netmask: '255.255.255.0', lower: '10.0.0.3', upper: '10.0.0.254'},
        ])
      end
    end
  end

  describe "read_guest_property" do
    it "reads the guest property of the machine referenced by the UUID" do
      key  = "/Foo/Bar"

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "guestproperty", "get", uuid, key, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Value: Baz\n"))

      expect(subject.read_guest_property(key)).to eq("Baz")
    end

    it "raises a virtualBoxGuestPropertyNotFound exception when the value is not set" do
      key  = "/Not/There"

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "guestproperty", "get", uuid, key, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "No value set!"))

      expect { subject.read_guest_property(key) }.
        to raise_error Vagrant::Errors::VirtualBoxGuestPropertyNotFound
    end
  end

  describe "read_guest_ip" do
    it "reads the guest property for the provided adapter number" do
      key = "/VirtualBox/GuestInfo/Net/1/V4/IP"

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "guestproperty", "get", uuid, key, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Value: 127.1.2.3"))

      value = subject.read_guest_ip(1)

      expect(value).to eq("127.1.2.3")
    end

    it "does not accept 0.0.0.0 as a valid IP address" do
      key = "/VirtualBox/GuestInfo/Net/1/V4/IP"

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "guestproperty", "get", uuid, key, an_instance_of(Hash)).
        and_return(subprocess_result(stdout: "Value: 0.0.0.0"))

      expect { subject.read_guest_ip(1) }.
        to raise_error Vagrant::Errors::VirtualBoxGuestPropertyNotFound
    end
  end

  describe "read_host_only_interfaces" do
    before {
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "list", "hostonlyifs", an_instance_of(Hash)).
        and_return(subprocess_result(stdout: output))
    }

    context "with empty output" do
      let(:output) { "" }

      it "returns an empty list" do
        expect(subject.read_host_only_interfaces).to eq([])
      end
    end

    context "with a single host only interface" do
      let(:output) {
        <<-OUTPUT.gsub(/^ */, '')
          Name:            vboxnet0
          GUID:            786f6276-656e-4074-8000-0a0027000000
          DHCP:            Disabled
          IPAddress:       172.28.128.1
          NetworkMask:     255.255.255.0
          IPV6Address:
          IPV6NetworkMaskPrefixLength: 0
          HardwareAddress: 0a:00:27:00:00:00
          MediumType:      Ethernet
          Status:          Up
          VBoxNetworkName: HostInterfaceNetworking-vboxnet0

        OUTPUT
      }

      it "returns a list with one entry describing that interface" do
        expect(subject.read_host_only_interfaces).to eq([{
          name:    'vboxnet0',
          ip:      '172.28.128.1',
          netmask: '255.255.255.0',
          status:  'Up',
        }])
      end
    end

    context "with multiple host only interfaces" do
      let(:output) {
        <<-OUTPUT.gsub(/^ */, '')
          Name:            vboxnet0
          GUID:            786f6276-656e-4074-8000-0a0027000000
          DHCP:            Disabled
          IPAddress:       172.28.128.1
          NetworkMask:     255.255.255.0
          IPV6Address:
          IPV6NetworkMaskPrefixLength: 0
          HardwareAddress: 0a:00:27:00:00:00
          MediumType:      Ethernet
          Status:          Up
          VBoxNetworkName: HostInterfaceNetworking-vboxnet0

          Name:            vboxnet1
          GUID:            5764a976-8479-8388-1245-8a0048080840
          DHCP:            Disabled
          IPAddress:       10.0.0.1
          NetworkMask:     255.255.255.0
          IPV6Address:
          IPV6NetworkMaskPrefixLength: 0
          HardwareAddress: 0a:00:27:00:00:01
          MediumType:      Ethernet
          Status:          Up
          VBoxNetworkName: HostInterfaceNetworking-vboxnet1

        OUTPUT
      }

      it "returns a list with one entry for each interface" do
        expect(subject.read_host_only_interfaces).to eq([
          {name: 'vboxnet0', ip: '172.28.128.1', netmask: '255.255.255.0', status: 'Up'},
          {name: 'vboxnet1', ip: '10.0.0.1', netmask: '255.255.255.0', status: 'Up'},
        ])
      end
    end
  end

  describe "remove_dhcp_server" do
    it "removes the dhcp server with the specified network name" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "dhcpserver", "remove", "--netname", "HostInterfaceNetworking-vboxnet0", an_instance_of(Hash)).
        and_return(subprocess_result(stdout: ''))

      subject.remove_dhcp_server("HostInterfaceNetworking-vboxnet0")
    end
  end
end
