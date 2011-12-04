require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::Loader do
  include_context "unit"

  let(:instance) { described_class.new }

  it "should load and return the configuration" do
    proc = Proc.new do |config|
      config.vagrant.dotfile_name = "foo"
    end

    instance.load_order = [:proc]
    instance.set(:proc, proc)
    config = instance.load

    config.vagrant.dotfile_name.should == "foo"
  end

  it "should raise proper error if there is a syntax error in a Vagrantfile" do
    instance.load_order = [:file]
    instance.set(:file, temporary_file("Vagrant:^Config"))
    expect { instance.load }.to raise_exception(Vagrant::Errors::VagrantfileSyntaxError)
  end
end
