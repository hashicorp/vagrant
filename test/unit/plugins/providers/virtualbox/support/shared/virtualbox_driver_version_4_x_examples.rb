shared_examples "a version 4.x virtualbox driver" do |options|
  before do
    raise ArgumentError, "Need virtualbox context to use these shared examples." if !(defined? vbox_context)
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
  end
end
