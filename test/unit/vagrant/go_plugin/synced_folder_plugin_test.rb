require_relative "../../base"

describe Vagrant::GoPlugin::SyncedFolderPlugin::SyncedFolder do
  let(:subject) {
    Class.new(described_class).tap { |c|
      c.plugin_client = client } }
  let(:client) { double("client") }
  let(:machine) { double("machine", to_json: "{}") }
  let(:folders) { double("folders", to_json: "{}") }
  let(:options) { double("options", to_json: "{}") }

  it "should be a GRPCPlugin" do
    expect(subject).to be_a(Vagrant::GoPlugin::GRPCPlugin)
  end

  describe "#cleanup" do
    it "should call plugin client" do
      expect(client).to receive(:cleanup).
        with(instance_of(Vagrant::Proto::SyncedFolders))
      subject.cleanup(machine, options)
    end
  end

  describe "#disable" do
    it "should call plugin client" do
      expect(client).to receive(:disable).
        with(instance_of(Vagrant::Proto::SyncedFolders))
      subject.disable(machine, folders, options)
    end
  end

  describe "#enable" do
    it "should call plugin client" do
      expect(client).to receive(:enable).
        with(instance_of(Vagrant::Proto::SyncedFolders))
      subject.enable(machine, folders, options)
    end
  end

  describe "#prepare" do
    it "should call plugin client" do
      expect(client).to receive(:prepare).
        with(instance_of(Vagrant::Proto::SyncedFolders))
      subject.prepare(machine, folders, options)
    end
  end

  describe "#usable?" do
    let(:response) { Vagrant::Proto::Valid.new(result: true) }

    it "should call the plugin client" do
      expect(client).to receive(:is_usable).
        with(instance_of(Vagrant::Proto::Machine)).
        and_return(response)
      expect(subject.usable?).to eq(true)
    end
  end

  describe "#name" do
    let(:response) { Vagrnat::Proto::Identifier.new(name: "dummy") }

    it "should call the plugin client" do
      expect(client).to receive(:name).and_return(response)
      expect(subject.name).to eq(response.name)
    end

    it "should only call the plugin client once" do
      expect(client).to receive(:name).once.and_return(response)
      expect(subject.name).to eq(response.name)
      expect(subject.name).to eq(response.name)
    end
  end
end
