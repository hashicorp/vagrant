require File.expand_path("../../../base", __FILE__)

require "vagrant/registry"

describe Vagrant::Config::Loader do
  include_context "unit"

  # This is just a dummy implementation of a configuraiton loader which
  # simply acts on hashes.
  let(:test_loader) do
    Class.new do
      def self.init
        {}
      end

      def self.load(proc)
        init.tap do |obj|
          proc.call(obj)
        end
      end

      def self.merge(old, new)
        old.merge(new)
      end
    end
  end

  let(:versions) do
    Vagrant::Registry.new.tap do |r|
      r.register("1") { test_loader }
    end
  end

  let(:version_order) { ["1"] }

  let(:instance) { described_class.new(versions, version_order) }

  it "should ignore non-existent load order keys" do
    instance.load_order = [:foo]
    instance.load
  end

  it "should load and return the configuration" do
    proc = Proc.new do |config|
      config[:foo] = "yep"
    end

    instance.load_order = [:proc]
    instance.set(:proc, proc)
    config = instance.load

    config[:foo].should == "yep"
  end

  it "should only run the same proc once" do
    count = 0
    proc = Proc.new do |config|
      config[:foo] = "yep"
      count += 1
    end

    instance.load_order = [:proc]
    instance.set(:proc, proc)

    5.times do
      result = instance.load

      # Verify the config result
      result[:foo].should == "yep"

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
