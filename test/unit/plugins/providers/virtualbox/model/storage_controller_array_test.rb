require File.expand_path("../../base", __FILE__)

describe VagrantPlugins::ProviderVirtualBox::Model::StorageControllerArray do
  include_context "unit"

  let(:controller1) { double("ide_controller", name: "IDE Controller", storage_bus: "IDE") }
  let(:controller2) { double("sata_controller", name: "SATA Controller", storage_bus: "SATA") }

  let(:primary_disk) { double("attachment", location: "/tmp/primary.vdi") }

  before do
    subject << controller1
    subject << controller2
  end

  describe "#get_controller" do
    it "gets a controller by name" do
      expect(subject.get_controller(name: "IDE Controller")).to eq(controller1)
    end

    it "gets a controller by storage bus" do
      expect(subject.get_controller(storage_bus: "SATA")).to eq(controller2)
    end
  end

  describe "#get_controller!" do
    it "gets a controller if it exists" do
      expect(subject.get_controller!(name: "IDE Controller")).to eq(controller1)
    end

    it "raises an exception if a matching storage controller can't be found" do
      expect { subject.get_controller!(name: "Foo Controller") }.
        to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
    end
  end

  describe "#get_primary_controller" do
    context "with one controller" do
      before do
        subject.replace([controller1])
      end

      it "returns the controller" do
        expect(subject.get_primary_controller).to eq(controller1)
      end
    end

    context "with multiple controllers" do
      before do
        allow(controller1).to receive(:attachments).and_return([])
        allow(controller2).to receive(:attachments).and_return([])
      end

      it "returns the SATA controller by default" do
        expect(subject.get_primary_controller).to eq(controller2)
      end

      it "returns the IDE controller if it has a hdd attached" do
        allow(controller1).to receive(:attachments).and_return([primary_disk])
        allow(subject).to receive(:hdd?).with(primary_disk).and_return(true)

        expect(subject.get_primary_controller).to eq(controller1)
      end

      it "raises an error if the machine doesn't have a SATA or an IDE controller" do
        subject.replace([])

        expect { subject.get_primary_controller }.to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
      end
    end
  end
end
