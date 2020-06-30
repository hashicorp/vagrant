require File.expand_path("../../base", __FILE__)

describe VagrantPlugins::ProviderVirtualBox::Model::StorageControllerArray do
  include_context "unit"

  let(:ide_controller) { double("ide_controller", name: "IDE Controller", storage_bus: "IDE") }
  let(:sata_controller) { double("sata_controller", name: "SATA Controller", storage_bus: "SATA") }

  let(:primary_disk) { {location: "/tmp/primary.vdi"} }

  before do
    subject.replace([ide_controller, sata_controller])
  end

  describe "#get_controller" do
    it "gets a controller by name" do
      expect(subject.get_controller(name: "IDE Controller")).to eq(ide_controller)
    end

    it "gets a controller by storage bus" do
      expect(subject.get_controller(storage_bus: "SATA")).to eq(sata_controller)
    end
  end

  describe "#get_controller!" do
    it "gets a controller if it exists" do
      expect(subject.get_controller!(name: "IDE Controller")).to eq(ide_controller)
    end

    it "raises an exception if a matching storage controller can't be found" do
      expect { subject.get_controller!(name: "Foo Controller") }.
        to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
    end
  end

  describe "#get_primary_controller" do
    context "with a single supported controller" do
      before do
        subject.replace([ide_controller])
        allow(ide_controller).to receive(:attachments).and_return([primary_disk])
      end

      it "returns the controller" do
        expect(subject.get_primary_controller).to eq(ide_controller)
      end
    end

    context "with multiple controllers" do
      before do
        allow(ide_controller).to receive(:attachments).and_return([])
        allow(sata_controller).to receive(:attachments).and_return([])
      end

      it "returns the SATA controller by default" do
        expect(subject.get_primary_controller).to eq(sata_controller)
      end

      it "returns the IDE controller if it has a hdd attached" do
        allow(ide_controller).to receive(:attachments).and_return([primary_disk])
        allow(subject).to receive(:hdd?).with(primary_disk).and_return(true)

        expect(subject.get_primary_controller).to eq(ide_controller)
      end

      it "raises an error if the machine doesn't have a SATA or an IDE controller" do
        subject.replace([])

        expect { subject.get_primary_controller }.to raise_error(Vagrant::Errors::VirtualBoxDisksNoSupportedControllers)
      end
    end
  end

  describe "#hdd?" do
    let(:attachment) { {} }
    it "determines whether the given attachment represents a hard disk" do
      expect(subject.send(:hdd?, attachment)).to be(false)
    end

    it "returns true for disk files ending in compatible extensions" do
      attachment[:location] = "/tmp/primary.vdi"
      expect(subject.send(:hdd?, attachment)).to be(true)
    end

    it "is case insensitive" do
      attachment[:location] = "/tmp/PRIMARY.VDI"
      expect(subject.send(:hdd?, attachment)).to be(true)
    end
  end

  describe "#get_primary_attachment" do
    let(:attachment) { {location: "/tmp/primary.vdi"} }

    before do
      allow(subject).to receive(:get_primary_controller).and_return(sata_controller)
    end

    it "returns the first attachment on the primary controller" do
      allow(sata_controller).to receive(:get_attachment).with(port: "0", device: "0").and_return(attachment)
      expect(subject.get_primary_attachment).to be(attachment)
    end

    it "raises an exception if no attachment exists at port 0, device 0" do
      allow(sata_controller).to receive(:get_attachment).with(port: "0", device: "0").and_return(nil)
      expect { subject.get_primary_attachment }.to raise_error(Vagrant::Errors::VirtualBoxDisksPrimaryNotFound)
    end
  end

  describe "#types" do
    it "returns a list of storage controller types" do
      expect(subject.send(:types)).to eq(["IDE", "SATA"])
    end
  end
end
