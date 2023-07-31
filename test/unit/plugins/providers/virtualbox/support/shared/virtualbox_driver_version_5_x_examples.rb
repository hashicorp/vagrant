# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

shared_examples "a version 5.x virtualbox driver" do |options|
  before do
    raise ArgumentError, "Need virtualbox context to use these shared examples." if !(defined? vbox_context)
  end

  describe "#shared_folders" do
    let(:folders) { [{:name=>"folder",
                     :hostpath=>"/Users/brian/vagrant-folder",
                     :transient=>false,
                     :SharedFoldersEnableSymlinksCreate=>true}]}

    let(:folders_automount) { [{:name=>"folder",
                     :hostpath=>"/Users/brian/vagrant-folder",
                     :transient=>false,
                     :automount=>true,
                     :SharedFoldersEnableSymlinksCreate=>true}]}

    let(:folders_disabled) { [{:name=>"folder",
                     :hostpath=>"/Users/brian/vagrant-folder",
                     :transient=>false,
                     :SharedFoldersEnableSymlinksCreate=>false}]}

    it "enables SharedFoldersEnableSymlinksCreate if true" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "setextradata", anything, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/folder", "1", {:env => {:LANG => "C"}, :notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "sharedfolder", "add", anything, "--name", "folder", "--hostpath", "/Users/brian/vagrant-folder", {:env => {:LANG => "C"}, :notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))
      subject.share_folders(folders)

    end

    it "enables automount if option is true" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "setextradata", anything, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/folder", "1", {:env => {:LANG => "C"}, :notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))

      expect(subprocess).to receive(:execute).
        with("VBoxManage", "sharedfolder", "add", anything, "--name", "folder", "--hostpath", "/Users/brian/vagrant-folder", "--automount", {:env => {:LANG => "C"}, :notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))
      subject.share_folders(folders_automount)

    end

    it "disables SharedFoldersEnableSymlinksCreate if false" do
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "sharedfolder", "add", anything, "--name", "folder", "--hostpath", "/Users/brian/vagrant-folder", {:env => {:LANG => "C"}, :notify=>[:stdout, :stderr]}).
        and_return(subprocess_result(exit_code: 0))
      subject.share_folders(folders_disabled)

    end
  end

  describe "#set_mac_address" do
    let(:mac) { "00:00:00:00:00:00" }

    after { subject.set_mac_address(mac) }

    it "should modify vm and set mac address" do
      expect(subprocess).to receive(:execute).with("VBoxManage", "modifyvm", anything, "--macaddress1", mac, anything).
        and_return(subprocess_result(exit_code: 0))
    end

    context "when mac address is falsey" do
      let(:mac) { nil }

      it "should modify vm and set mac address to automatic value" do
        expect(subprocess).to receive(:execute).with("VBoxManage", "modifyvm", anything, "--macaddress1", "auto", anything).
          and_return(subprocess_result(exit_code: 0))
      end
    end
  end

  describe "#ssh_port" do
    let(:forwards) {
      [[1, "ssh", 2222, 22, "127.0.0.1"],
        [1, "ssh", 8080, 80, ""]]
    }

    before { allow(subject).to receive(:read_forwarded_ports).and_return(forwards) }

    it "should return the host port" do
      expect(subject.ssh_port(22)).to eq(2222)
    end

    context "when multiple matches are available" do
      let(:forwards) {
        [[1, "ssh", 2222, 22, "127.0.0.1"],
          [1, "", 2221, 22, ""]]
      }

      it "should choose localhost port forward" do
        expect(subject.ssh_port(22)).to eq(2222)
      end

      context "when multiple named matches are available" do
        let(:forwards) {
          [[1, "ssh", 2222, 22, "127.0.0.1"],
            [1, "SSH", 2221, 22, "127.0.0.1"]]
        }

        it "should choose lowercased name forward" do
          expect(subject.ssh_port(22)).to eq(2222)
        end
      end
    end

    context "when only ports are defined" do
      let(:forwards) {
        [[1, "", 2222, 22, ""]]
      }

      it "should return the host port" do
        expect(subject.ssh_port(22)).to eq(2222)
      end
    end

    context "when no matches are available" do
      let(:forwards) { [] }

      it "should return nil" do
        expect(subject.ssh_port(22)).to be_nil
      end
    end
  end

  describe "#read_guest_ip" do
    context "when guest ip ends in .1" do
      before do
        key = "/VirtualBox/GuestInfo/Net/1/V4/IP"

        expect(subprocess).to receive(:execute).
          with("VBoxManage", "guestproperty", "get", uuid, key, an_instance_of(Hash)).
          and_return(subprocess_result(stdout: "Value: 172.28.128.1"))
      end

      it "should raise an error" do
        expect { subject.read_guest_ip(1) }.to raise_error(Vagrant::Errors::VirtualBoxGuestPropertyNotFound)
      end
    end
  end

  describe "#valid_ip_address?" do
    context "when ip is 0.0.0.0" do
      let(:ip) { "0.0.0.0" }

      it "should be false" do
        result = subject.send(:valid_ip_address?, ip)
        expect(result).to be(false)
      end
    end

    context "when ip address is nil" do
      let(:ip) { nil }

      it "should be false" do
        result = subject.send(:valid_ip_address?, ip)
        expect(result).to be(false)
      end
    end
  end
end
