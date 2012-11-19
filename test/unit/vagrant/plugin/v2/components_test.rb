require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Components do
  let(:instance) { described_class.new }

  it "should have provider configs" do
    instance.provider_configs.should be_kind_of(Vagrant::Registry)
  end
end
