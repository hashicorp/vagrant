require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::Host do
  include_context "capability_helpers"

  let(:capabilities) { {} }
  let(:hosts)  { {} }
  let(:env) { Object.new }

  it "initializes the capabilities" do
    expect_any_instance_of(described_class).to receive(:initialize_capabilities!).
      with(:foo, hosts, capabilities, env)

    described_class.new(:foo, hosts, capabilities, env)
  end
end
