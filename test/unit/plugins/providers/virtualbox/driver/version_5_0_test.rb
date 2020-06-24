require "pathname"
require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_5_0 do
  include_context "virtualbox"

  let(:vbox_version) { "5.0.0" }
  let(:controller_name) { "controller" }

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_5_0.new(uuid) }

  it_behaves_like "a version 4.x virtualbox driver"
  it_behaves_like "a version 5.x virtualbox driver"

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
 2: Number of CPUs: 2
    (change with "--vsys 0 --cpus <n>")
 3: Guest memory: 384 MB
    (change with "--vsys 0 --memory <MB>")
 4: Network adapter: orig NAT, config 3, extra slot=0;type=NAT
 5: CD-ROM
    (disable with "--vsys 0 --unit 5 --ignore")
 6: IDE controller, type PIIX4
    (disable with "--vsys 0 --unit 6 --ignore")
 7: IDE controller, type PIIX4
   (disable with "--vsys 0 --unit 7 --ignore")
 8: SATA controller, type AHCI
    (disable with "--vsys 0 --unit 8 --ignore")
 9: Hard disk image: source image=box-disk1.vmdk, target path=/home/user/VirtualBox VMs/precise64/box-disk1.vmdk, controller=8;channel=0
    (change target path with "--vsys 0 --unit 9 --disk path";
    disable with "--vsys 0 --unit 9 --ignore")
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
  end

  describe "#attach_disk" do
    it "attaches a device to the specified controller" do
      expect(subject).to receive(:execute) do |*args|
        storagectl = args[args.index("--storagectl") + 1]
        expect(storagectl).to eq(controller_name)
      end
      subject.attach_disk(controller_name, anything, anything, anything, anything) 
    end
  end

  describe "#remove_disk" do
    it "removes a disk from the specified controller" do
      expect(subject).to receive(:execute) do |*args|
        storagectl = args[args.index("--storagectl") + 1]
        expect(storagectl).to eq(controller_name)
      end
      subject.remove_disk(controller_name, anything, anything)
    end
  end

  describe "#read_storage_controllers" do
    before do
      allow(subject).to receive(:show_vm_info).and_return(
        { "storagecontrollername0" => "SATA Controller",
          "storagecontrollertype0" => "IntelAhci",
          "storagecontrollermaxportcount0" => "30",
          "SATA Controller-ImageUUID-0-0" => "12345",
          "SATA Controller-ImageUUID-1-0" => "67890" }
      )
    end

    it "returns a list of storage controllers" do
      storage_controllers = subject.read_storage_controllers

      expect(storage_controllers.first.name).to eq("SATA Controller")
      expect(storage_controllers.first.type).to eq("IntelAhci")
      expect(storage_controllers.first.maxportcount).to eq(30)
    end

    it "includes attachments for each storage controller" do
      storage_controllers = subject.read_storage_controllers

      expect(storage_controllers.first.attachments).to include(port: "0", device: "0", uuid: "12345")
      expect(storage_controllers.first.attachments).to include(port: "1", device: "0", uuid: "67890")
    end
  end

  describe "#get_storage_controller" do
    let(:storage_controllers) { [double("controller", name: "IDE Controller")] }

    before do
      allow(subject).to receive(:read_storage_controllers).and_return(storage_controllers)
    end

    it "refreshes the storage controller state" do
      expect(subject).to receive(:read_storage_controllers)

      subject.get_storage_controller("IDE Controller")
    end

    it "returns the storage controller matching the specified name" do
      controller = subject.get_storage_controller("IDE Controller")

      expect(controller.name).to eq("IDE Controller")
    end

    it "raises an exception if the storage controller can't be found" do
      expect { subject.get_storage_controller("SCSI Controller") }.
        to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
    end
  end
end
