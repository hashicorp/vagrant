# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "pathname"
require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_6_0 do
  include_context "virtualbox"

  let(:vbox_version) { "6.0.0" }

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_6_0.new(uuid) }

  it_behaves_like "a version 4.x virtualbox driver"
  it_behaves_like "a version 5.x virtualbox driver"
  it_behaves_like "a version 6.x virtualbox driver"

  describe "#import" do
    let(:ovf) { double("ovf") }
    let(:machine_id) { double("machine_id") }
    let(:output) {<<-OUTPUT
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interpreting /home/user/.vagrant.d/boxes/hashicorp-VAGRANTSLASH-precise64/1.1.0/virtualbox/box.ovf...
OK.
Disks:
  vmdisk1       85899345920     -1      http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized       box-disk1.vmdk  -1      -1

Virtual system 0:
 0: Suggested OS type: "Ubuntu_64"
    (change with "--vsys 0 --ostype <type>"; use "list ostypes" to list all possible values)
 1: Suggested VM name "precise64"
    (change with "--vsys 0 --vmname <name>")
 2: Suggested VM group "/"
    (change with "--vsys 0 --group <group>")
 3: Suggested VM settings file name "/home/user/VirtualBox VMs/precise64/precise64.vbox"
    (change with "--vsys 0 --settingsfile <filename>")
 4: Suggested VM base folder "/home/vagrant/VirtualBox VMs"
    (change with "--vsys 0 --basefolder <path>")
 5: Number of CPUs: 2
    (change with "--vsys 0 --cpus <n>")
 6: Guest memory: 384 MB
    (change with "--vsys 0 --memory <MB>")
 7: Network adapter: orig NAT, config 3, extra slot=0;type=NAT
 8: CD-ROM
    (disable with "--vsys 0 --unit 8 --ignore")
 9: IDE controller, type PIIX4
    (disable with "--vsys 0 --unit 9 --ignore")
10: IDE controller, type PIIX4
    (disable with "--vsys 0 --unit 10 --ignore")
11: SATA controller, type AHCI
    (disable with "--vsys 0 --unit 11 --ignore")
12: Hard disk image: source image=box-disk1.vmdk, target path=box-disk1.vmdk, controller=11;channel=0
    (change target path with "--vsys 0 --unit 12 --disk path";
    disable with "--vsys 0 --unit 12 --ignore")
OUTPUT
    }

    before do
      allow(Vagrant::Util::Platform).to receive(:windows_path).
        with(ovf).and_return(ovf)
      allow(subject).to receive(:execute).with("import", "-n", ovf).
        and_return(output)
      allow(subject).to receive(:execute).with("import", ovf, any_args)
      allow(subject).to receive(:get_machine_id).and_return(machine_id)
    end

    it "should return the machine id" do
      expect(subject).to receive(:get_machine_id).and_return(machine_id)
      expect(subject.import(ovf)).to eq(machine_id)
    end

    it "should return machine id using custom name" do
      expect(subject).to receive(:get_machine_id).with(/.*precise64_.+/).and_return(machine_id)
      expect(subject.import(ovf)).to eq(machine_id)
    end

    it "should include disk image on import" do
      expect(subject).to receive(:execute).with("import", "-n", ovf).and_return(output)
      expect(subject).to receive(:execute) do |*args|
        match = args[3, args.size].detect { |a| a.include?("disk1.vmdk") }
        expect(match).to include("disk1.vmdk")
      end
      expect(subject.import(ovf)).to eq(machine_id)
    end

    it "should include full path for disk image on import" do
      expect(subject).to receive(:execute).with("import", "-n", ovf).and_return(output)
      expect(subject).to receive(:execute) do |*args|
        dpath = args[3, args.size].detect { |a| a.include?("disk1.vmdk") }
        expect(Pathname.new(dpath).absolute?).to be_truthy
      end
      expect(subject.import(ovf)).to eq(machine_id)
    end

    context "suggested name is not provided" do
      before { output.sub!(/Suggested VM name/, "") }

      it "should raise an error" do
        expect { subject.import(ovf) }.to raise_error(Vagrant::Errors::VirtualBoxNoName)
      end
    end

    context "when within windows" do
      before do
        allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      end

      let(:output) {<<-OUTPUT
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interpreting C:\\home\\user\\.vagrant.d\\boxes\\hashicorp-VAGRANTSLASH-precise64\\1.1.0\\virtualbox\\box.ovf...
OK.
Disks:
  vmdisk1       85899345920     -1      http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized       box-disk1.vmdk  -1      -1

Virtual system 0:
 0: Suggested OS type: "Ubuntu_64"
    (change with "--vsys 0 --ostype <type>"; use "list ostypes" to list all possible values)
 1: Suggested VM name "precise64"
    (change with "--vsys 0 --vmname <name>")
 2: Suggested VM group "/"
    (change with "--vsys 0 --group <group>")
 3: Suggested VM settings file name "C:\\home\\user\\VirtualBox VMs\\precise64\\precise64.vbox"
    (change with "--vsys 0 --settingsfile <filename>")
 4: Suggested VM base folder "C:\\home\\vagrant\\VirtualBox VMs"
    (change with "--vsys 0 --basefolder <path>")
 5: Number of CPUs: 2
    (change with "--vsys 0 --cpus <n>")
 6: Guest memory: 384 MB
    (change with "--vsys 0 --memory <MB>")
 7: Network adapter: orig NAT, config 3, extra slot=0;type=NAT
 8: CD-ROM
    (disable with "--vsys 0 --unit 8 --ignore")
 9: IDE controller, type PIIX4
    (disable with "--vsys 0 --unit 9 --ignore")
10: IDE controller, type PIIX4
    (disable with "--vsys 0 --unit 10 --ignore")
11: SATA controller, type AHCI
    (disable with "--vsys 0 --unit 11 --ignore")
12: Hard disk image: source image=box-disk1.vmdk, target path=box-disk1.vmdk, controller=11;channel=0
    (change target path with "--vsys 0 --unit 12 --disk path";
    disable with "--vsys 0 --unit 12 --ignore")
OUTPUT
      }

      it "should include disk image on import" do
        expect(subject).to receive(:execute).with("import", "-n", ovf).and_return(output)
        expect(subject).to receive(:execute) do |*args|
          match = args[3, args.size].detect { |a| a.include?("disk1.vmdk") }
          expect(match).to include("disk1.vmdk")
        end
        expect(subject.import(ovf)).to eq(machine_id)
      end

      it "should update the suggested VM path from default box name" do
        expect(subject).to receive(:execute).with("import", "-n", ovf).and_return(output)
        expect(subject).to receive(:execute) do |*args|
          match = args[3, args.size].detect { |a| a.include?("box-disk1.vmdk") }
          expect(match).not_to include("/precise64/box-disk1.vmdk")
          expect(match).to match(/.+precise64_.+?\/box-disk1.vmdk/)
        end
        expect(subject.import(ovf)).to eq(machine_id)
      end

    end
  end
end
