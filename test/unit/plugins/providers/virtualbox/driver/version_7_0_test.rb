require "stringio"
require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_7_0 do
  include_context "virtualbox"

  let(:vbox_version) { "7.0.0" }

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_7_0.new(uuid) }

  it_behaves_like "a version 5.x virtualbox driver"
  it_behaves_like "a version 6.x virtualbox driver"

  describe "#read_forwarded_ports" do
    let(:uuid) { "MACHINE-UUID" }
    let(:cfg_path) { "MACHINE_CONFIG_PATH" }
    let(:vm_info) {
%(name="vagrant-test_default_1665781960041_56631"
Encryption:     disabled
groups="/"
ostype="Ubuntu (64-bit)"
UUID="#{uuid}"
CfgFile="#{cfg_path}"
SnapFldr="/VirtualBox VMs/vagrant-test_default_1665781960041_56631/Snapshots"
LogFldr="/VirtualBox VMs/vagrant-test_default_1665781960041_56631/Logs"
memory=1024)
    }
    let(:config_file) {
      StringIO.new(
%(<?xml version="1.0"?>
<VirtualBox xmlns="http://www.virtualbox.org/" version="1.19-linux">
  <Machine uuid="{623842dc-0947-4143-aa4e-7d180c5eb348}" name="vagrant-test_default_1665781960041_56631" OSType="Ubuntu_64" snapshotFolder="Snapshots">
    <Hardware>
      <Network>
        <Adapter slot="0" enabled="true" MACAddress="080027BB1475" type="82540EM">
          <NAT localhost-reachable="true">
            <DNS use-proxy="true"/>
            <Forwarding name="ssh" proto="1" hostip="127.0.0.1" hostport="2222" guestport="22"/>
            <Forwarding name="tcp7700" proto="1" hostport="7700" guestport="80"/>
          </NAT>
        </Adapter>
        <Adapter slot="1" enabled="true" MACAddress="080027DD5ADF" type="82540EM">
          <DisabledModes>
            <InternalNetwork name="intnet"/>
            <NATNetwork name="NatNetwork"/>
          </DisabledModes>
          <HostOnlyInterface name="vboxnet0"/>
        </Adapter>
      </Network>
    </Hardware>
  </Machine>
</VirtualBox>)
      )
    }

    before do
      allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).to receive(:version).and_return(vbox_version)
    end

    describe "VirtualBox version 7.0.0" do
      let(:vbox_version) { "7.0.0" }

      before do
        allow(subject).to receive(:execute).with("showvminfo", uuid, any_args).and_return(vm_info)
        allow(File).to receive(:open).with(cfg_path, "r").and_yield(config_file)
      end

      it "should return two port forward values" do
        expect(subject.read_forwarded_ports.size).to eq(2)
      end

      it "should have port forwards on slot one" do
        subject.read_forwarded_ports.each do |fwd|
          expect(fwd.first).to eq(1)
        end
      end

      it "should include host ip for ssh forward" do
        fwd = subject.read_forwarded_ports.detect { |f| f[1] == "ssh" }
        expect(fwd).not_to be_nil
        expect(fwd.last).to eq("127.0.0.1")
      end

      describe "when config file cannot be determine" do
        let(:vm_info) { %(name="vagrant-test_default_1665781960041_56631") }

        it "should raise a custom error" do
          expect(File).not_to receive(:open).with(cfg_path, "r")

          expect { subject.read_forwarded_ports }.to raise_error(Vagrant::Errors::VirtualBoxConfigNotFound)
        end
      end
    end

    describe "VirtualBox version greater than 7.0.0" do
      let(:vbox_version) { "7.0.1" }

      before do
        allow(subject).to receive(:execute).with("showvminfo", uuid, any_args).and_return(vm_info)
      end

      it "should not read configuration file" do
        expect(File).not_to receive(:open).with(cfg_path, "r")
        subject.read_forwarded_ports
      end
    end

  end
end
