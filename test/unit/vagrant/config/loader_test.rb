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

  it "should only run the same proc once" do
    count = 0
    proc = Proc.new do |config|
      config.vagrant.dotfile_name = "foo"
      count += 1
    end

    instance.load_order = [:proc]
    instance.set(:proc, proc)

    5.times do
      result = instance.load

      # Verify the config result
      result.vagrant.dotfile_name.should == "foo"

      # Verify the count is only one
      count.should == 1
    end
  end

  it "should only load configuration files once" do
    $_config_data = 0

    # We test both setting a file multiple times as well as multiple
    # loads, since both should not cache the data.
    file = temporary_file("$_config_data += 1")
    instance.load_order = [:file]
    5.times { instance.set(:file, file) }
    5.times { instance.load }

    $_config_data.should == 1
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
    expect { instance.set(:file, temporary_file("Vagrant:^Config")) }.
      to raise_exception(Vagrant::Errors::VagrantfileSyntaxError)
  end
end
