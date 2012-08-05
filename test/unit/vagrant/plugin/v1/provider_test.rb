require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Provider do
  let(:machine)  { Object.new }
  let(:instance) { described_class.new(machine) }

  it "should return nil by default for actions" do
    instance.action(:whatever).should be_nil
  end

  it "should return nil by default for ssh info" do
    instance.ssh_info.should be_nil
  end

  it "should return nil by default for state" do
    instance.state.should be_nil
  end
end
