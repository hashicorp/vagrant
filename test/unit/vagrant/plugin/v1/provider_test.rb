require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Provider do
  let(:instance) { described_class.new }

  it "should return nil by default for actions" do
    instance.action(:whatever).should be_nil
  end
end
