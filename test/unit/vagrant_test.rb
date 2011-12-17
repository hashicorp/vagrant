require File.expand_path("../base", __FILE__)

describe Vagrant do
  it "has the path to the source root" do
    described_class.source_root.should == Pathname.new(File.expand_path("../../../", __FILE__))
  end

  it "has a registry for commands" do
    described_class.commands.should be_a(Vagrant::Registry)
  end

  it "has a registry for config keys" do
    described_class.config_keys.should be_a(Vagrant::Registry)
  end

  it "has a registry for hosts" do
    described_class.hosts.should be_a(Vagrant::Registry)
  end

  it "has a registry for guests" do
    described_class.guests.should be_a(Vagrant::Registry)
  end

  it "has a registry for provisioners" do
    described_class.provisioners.should be_a(Vagrant::Registry)
  end
end
