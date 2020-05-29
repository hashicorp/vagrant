require File.expand_path("../../base", __FILE__)

describe VagrantPlugins::ProviderVirtualBox::Model::StorageController do
  include_context "unit"

  let(:name) {}
  let(:type) {}
  let(:maxportcount) {}
  let(:attachments) {}

  subject { described_class.new(name, type, maxportcount, attachments) }

  describe "#sata_controller?" do
    let(:type) { "IntelAhci" }

    it "is true for a SATA type" do
      expect(subject.sata_controller?).to be(true)
    end
  end

  describe "#ide_controller?" do
    let(:type) { "PIIX4" }

    it "is true for an IDE type" do
      expect(subject.ide_controller?).to be(true)
    end
  end
end
