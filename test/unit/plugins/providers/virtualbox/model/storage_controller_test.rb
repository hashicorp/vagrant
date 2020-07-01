require File.expand_path("../../base", __FILE__)

describe VagrantPlugins::ProviderVirtualBox::Model::StorageController do
  include_context "unit"

  let(:name) {}
  let(:type) { "IntelAhci" }
  let(:maxportcount) { 30 }
  let(:attachments) {}

  subject { described_class.new(name, type, maxportcount, attachments) }

  describe "#initialize" do
    context "with SATA controller type" do
      it "recognizes a SATA controller" do
        expect(subject.sata?).to be(true)
      end

      it "calculates the maximum number of attachments" do
        expect(subject.limit).to eq(30)
      end
    end

    context "with IDE controller type" do
      let(:type) { "PIIX4" }
      let(:maxportcount) { 2 }

      it "recognizes an IDE controller" do
        expect(subject.ide?).to be(true)
      end

      it "calculates the maximum number of attachments" do
        expect(subject.limit).to eq(4)
      end
    end

    context "with some other type" do
      let(:type) { "foo" }

      it "is unknown" do
        expect(subject.ide?).to be(false)
        expect(subject.sata?).to be(false)
      end
    end
  end
end
