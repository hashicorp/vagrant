require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/container/client")

describe VagrantPlugins::ContainerProvisioner::Client do
  
  let(:machine) { double("machine") }
  let(:container_command) { double("docker") }
  subject { described_class.new(machine, container_command) }

  describe "#container_name" do
    it "converts a container name to a run appropriate form" do
      config = { :name => "test/test:1.1.1", :original_name => "test/test:1.1.1" }
      expect(subject.container_name(config)).to eq("test-test-1.1.1")
    end
  end
end
