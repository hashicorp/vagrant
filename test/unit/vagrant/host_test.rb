require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::Host do
  include_context "capability_helpers"

  let(:capabilities) { {} }
  let(:hosts)  { {} }

  it "initializes the capabilities" do
    described_class.any_instance.should_receive(:initialize_capabilities!).
      with(:foo, hosts, capabilities)

    described_class.new(:foo, hosts, capabilities)
  end
end
