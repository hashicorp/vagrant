require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Communicator do
  let(:machine)  { Object.new }

  it "should not match by default" do
    described_class.match?(machine).should_not be
  end
end
