require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/noop/config")

describe VagrantPlugins::NoopDeploy::Config do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#validate" do
  end
end
