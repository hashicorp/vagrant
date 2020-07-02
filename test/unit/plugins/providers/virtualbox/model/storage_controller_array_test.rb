require File.expand_path("../../base", __FILE__)

describe VagrantPlugins::ProviderVirtualBox::Model::StorageControllerArray do
  include_context "unit"

  let(:controller1) { double("controller1", name: "IDE Controller", supported?: true, boot_priority: 1) }
  let(:controller2) { double("controller2", name: "SATA Controller", supported?: true, boot_priority: 2) }

  let(:primary_disk) { {location: "/tmp/primary.vdi"} }

  before do
    subject.replace([controller1, controller2])
  end

  describe "#get_controller" do
    it "gets a controller by name" do
      expect(subject.get_controller("IDE Controller")).to eq(controller1)
    end

    it "raises an exception if a matching storage controller can't be found" do
      expect { subject.get_controller(name: "Foo Controller") }.
        to raise_error(Vagrant::Errors::VirtualBoxDisksControllerNotFound)
    end
  end

  describe "#get_primary_controller" do
    context "with a single supported controller" do
      before do
        subject.replace([controller1])
        allow(controller1).to receive(:attachments).and_return([primary_disk])
      end

      it "returns the controller" do
        expect(subject.get_primary_controller).to eq(controller1)
      end
    end

    context "with multiple controllers" do
      before do
        allow(controller1).to receive(:attachments).and_return([])
        allow(controller2).to receive(:attachments).and_return([primary_disk])
      end

      it "returns the first supported controller with a disk attached" do
        expect(subject.get_primary_controller).to eq(controller2)
      end

      it "raises an error if the primary disk is attached to an unsupported controller" do
        allow(controller2).to receive(:supported?).and_return(false)

        expect { subject.get_primary_controller }.
          to raise_error(Vagrant::Errors::VirtualBoxDisksNoSupportedControllers)
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
      allow(subject).to receive(:get_primary_controller).and_return(controller2)
    end

    it "returns the first attachment on the primary controller" do
      allow(controller2).to receive(:get_attachment).with(port: "0", device: "0").and_return(attachment)
      expect(subject.get_primary_attachment).to be(attachment)
    end

    it "raises an exception if no attachment exists at port 0, device 0" do
      allow(controller2).to receive(:get_attachment).with(port: "0", device: "0").and_return(nil)
      expect { subject.get_primary_attachment }.to raise_error(Vagrant::Errors::VirtualBoxDisksPrimaryNotFound)
    end
  end

  describe "#get_dvd_controller" do
    context "with one controller" do
      let(:controller) { double("controller", supported?: true) }

      before do
        subject.replace([controller])
      end

      it "returns the controller" do
        expect(subject.get_dvd_controller).to be(controller)
      end

      it "raises an exception if the controller is unsupported" do
        allow(controller).to receive(:supported?).and_return(false)

        expect { subject.get_dvd_controller }.to raise_error(Vagrant::Errors::VirtualBoxDisksNoSupportedControllers)
      end
    end

    context "with multiple controllers" do
      let(:controller1) { double("controller", supported?: true, boot_priority: 2) }
      let(:controller2) { double("controller", supported?: true, boot_priority: 1) }

      before do
        subject.replace([controller1, controller2])
      end

      it "returns the first supported controller" do
        expect(subject.get_dvd_controller).to be(controller2)
      end

      it "raises an exception if no controllers are supported" do
        allow(controller1).to receive(:supported?).and_return(false)
        allow(controller2).to receive(:supported?).and_return(false)

        expect { subject.get_dvd_controller }.to raise_error(Vagrant::Errors::VirtualBoxDisksNoSupportedControllers)
      end
    end
  end
end
