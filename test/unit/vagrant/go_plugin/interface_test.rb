require_relative "../../base"

describe Vagrant::GoPlugin::Interface do
  before do
    allow_any_instance_of(described_class).to receive(:_setup)
  end

  describe "#load_plugins" do
    let(:path) { double("path", to_s: "path") }

    it "should raise error if path is not a directory" do
      expect(File).to receive(:directory?).with(path.to_s).and_return(false)
      expect { subject.load_plugins(path) }.to raise_error(ArgumentError)
    end

    it "should load plugins if path is a directory" do
      expect(File).to receive(:directory?).with(path.to_s).and_return(true)
      expect(subject).to receive(:_load_plugins).with(path.to_s)
      subject.load_plugins(path)
    end
  end

  describe "#register_plugins" do
    it "should load Provider and SyncedFolder plugins" do
      expect(subject).to receive(:load_providers)
      expect(subject).to receive(:load_synced_folders)
      subject.register_plugins
    end
  end

  describe "#setup" do
    after { subject }

    it "should register at_exit action" do
      expect(Kernel).to receive(:at_exit)
      subject
    end

    it "should run the setup action" do
      expect_any_instance_of(described_class).to receive(:_setup)
    end

    it "should only run the setup process once" do
      expect_any_instance_of(described_class).to receive(:_setup).once
      expect(subject.logger).to receive(:warn)
      subject.setup
    end
  end

  describe "#teardown" do
    it "should run the teardown action" do
      expect(subject).to receive(:_teardown)
      subject.teardown
    end
  end
end
