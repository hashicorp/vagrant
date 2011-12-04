require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::Loader do
  include_context "unit"

  let(:instance) { described_class.new }

  it "should ignore non-existent load order keys" do
    instance.load_order = [:foo]
    instance.load
  end

  it "should load and return the configuration" do
    proc = Proc.new do |config|
      config.vagrant.dotfile_name = "foo"
    end

    instance.load_order = [:proc]
    instance.set(:proc, proc)
    config = instance.load

    config.vagrant.dotfile_name.should == "foo"
  end

  it "should only load configuration files once" do
    $_config_data = 0

    instance.load_order = [:file]
    instance.set(:file, temporary_file("$_config_data += 1"))
    5.times { instance.load }

    $_config_data.should == 1
  end

  it "should clear cache on setting to a new value" do
    $_config_data = 0

    instance.load_order = [:proc]
    instance.set(:proc, temporary_file("$_config_data += 1"))
    5.times { instance.load }

    instance.set(:proc, temporary_file("$_config_data += 1"))
    5.times { instance.load }

    $_config_data.should == 2
  end

  it "should not clear the cache if setting to the same value multiple times" do
    $_config_data = 0

    file = temporary_file("$_config_data += 1")

    instance.load_order = [:proc]
    instance.set(:proc, file)
    5.times { instance.load }

    instance.set(:proc, file)
    5.times { instance.load }

    $_config_data.should == 1
  end

  it "should raise proper error if there is a syntax error in a Vagrantfile" do
    instance.load_order = [:file]
    instance.set(:file, temporary_file("Vagrant:^Config"))
    expect { instance.load }.to raise_exception(Vagrant::Errors::VagrantfileSyntaxError)
  end
end
