require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Provider do
  let(:machine)  { Object.new }
  let(:instance) { described_class.new(machine) }

  it "should return nil by default for actions" do
    expect(instance.action(:whatever)).to be_nil
  end

  it "should return nil by default for ssh info" do
    expect(instance.ssh_info).to be_nil
  end

  it "should return nil by default for state" do
    expect(instance.state).to be_nil
  end
end
