require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/config/chef_zero")

describe VagrantPlugins::Chef::Config::ChefZero do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#nodes_path" do
    it "defaults to an array" do
      subject.finalize!
      expect(subject.nodes_path).to be_a(Array)
      expect(subject.nodes_path).to be_empty
    end
  end
end
