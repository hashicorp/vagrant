require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/docker/synced_folder")

describe VagrantPlugins::DockerProvider::SyncedFolder do
  subject { described_class.new }

  describe "#usable?" do
    let(:machine) { double("machine") }

    before do
      machine.stub(provider_name: :docker)
    end

    it "is usable" do
      expect(subject).to be_usable(machine)
    end

    it "is not usable if provider isn't docker" do
      machine.stub(provider_name: :virtualbox)
      expect(subject).to_not be_usable(machine)
    end

    it "raises an error if bad provider if specified" do
      machine.stub(provider_name: :virtualbox)
      expect { subject.usable?(machine, true) }.
        to raise_error(VagrantPlugins::DockerProvider::Errors::SyncedFolderNonDocker)
    end
  end
end
