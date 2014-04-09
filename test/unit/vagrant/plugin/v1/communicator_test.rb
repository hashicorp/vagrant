require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Communicator do
  let(:machine)  { Object.new }

  it "should not match by default" do
    expect(described_class.match?(machine)).not_to be
  end
end
