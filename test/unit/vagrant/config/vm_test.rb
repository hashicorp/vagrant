require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::VMConfig do
  include_context "unit"

  it "merges by appending forwarded ports" do
    a = described_class.new
    a.forward_port 80, 8080

    b = described_class.new
    b.forward_port 100, 1000

    c = a.merge(b)
    c.forwarded_ports.length.should == 2
    c.forwarded_ports[0][:guestport].should == 80
    c.forwarded_ports[0][:hostport].should == 8080
    c.forwarded_ports[1][:guestport].should == 100
    c.forwarded_ports[1][:hostport].should == 1000
  end

  it "merges by merging shared folders" do
    a = described_class.new
    a.share_folder "a", "/guest", "/host"
    a.share_folder "b", "/guest", "/host"

    b = described_class.new
    b.share_folder "c", "/guest", "/host"

    c = a.merge(b)
    c.shared_folders.has_key?("a").should be
    c.shared_folders.has_key?("b").should be
    c.shared_folders.has_key?("c").should be
  end

  it "merges by appending networks" do
    a = described_class.new
    a.network :hostonly, "33.33.33.10"

    b = described_class.new
    b.network :hostonly, "33.33.33.11"

    c = a.merge(b)
    c.networks.length.should == 2
    c.networks[0].should == [:hostonly, ["33.33.33.10"]]
    c.networks[1].should == [:hostonly, ["33.33.33.11"]]
  end

  it "merges by appending provisioners" do
    a = described_class.new
    a.provision :foo

    b = described_class.new
    b.provision :bar

    c = a.merge(b)
    c.provisioners.length.should == 2
    c.provisioners[0].shortcut.should == :foo
    c.provisioners[1].shortcut.should == :bar
  end

  it "merges by appending customizations" do
    a = described_class.new
    a.customize "a"

    b = described_class.new
    b.customize "b"

    c = a.merge(b)
    c.customizations.should == ["a", "b"]
  end
end
