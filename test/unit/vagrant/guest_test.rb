require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::Guest do
  include_context "unit"

  let(:capabilities) { {} }
  let(:guests)  { {} }
  let(:machine) do
    double("machine").tap do |m|
      m.stub(:inspect => "machine")
      m.stub(:config => double("config"))
      m.config.stub(:vm => double("vm_config"))
      m.config.vm.stub(:guest => nil)
    end
  end

  subject { described_class.new(machine, guests, capabilities) }

  # This registers a capability with a specific guest
  def register_capability(guest, capability, options=nil)
    options ||= {}

    cap = Class.new do
      if !options[:corrupt]
        define_method(capability) do |*args|
          raise "cap: #{capability} #{args.inspect}"
        end
      end
    end

    capabilities[guest] ||= {}
    capabilities[guest][capability] = cap.new
  end

  # This registers a guest with the class.
  #
  # @param [Symbol] name Name of the guest
  # @param [Symbol] parent Name of the parent
  # @param [Boolean] detect Whether or not to detect properly
  def register_guest(name, parent, detect)
    guest = Class.new(Vagrant.plugin("2", "guest")) do
      define_method(:name) do
        name
      end

      define_method(:detect?) do |m|
        detect
      end
    end

    guests[name] = [guest, parent]
  end

  describe "#capability" do
    before :each do
      register_guest(:foo, nil, true)
      register_guest(:bar, :foo, true)

      subject.detect!
    end

    it "executes the capability" do
      register_capability(:bar, :test)

      expect { subject.capability(:test) }.
        to raise_error(RuntimeError, "cap: test [machine]")
    end

    it "executes the capability with arguments" do
      register_capability(:bar, :test)

      expect { subject.capability(:test, 1) }.
        to raise_error(RuntimeError, "cap: test [machine, 1]")
    end

    it "raises an exception if the capability doesn't exist" do
      expect { subject.capability(:what_is_this_i_dont_even) }.
        to raise_error(Vagrant::Errors::GuestCapabilityNotFound)
    end

    it "raises an exception if the method doesn't exist on the module" do
      register_capability(:bar, :test_is_corrupt, corrupt: true)

      expect { subject.capability(:test_is_corrupt) }.
        to raise_error(Vagrant::Errors::GuestCapabilityInvalid)
    end
  end

  describe "#capability?" do
    before :each do
      register_guest(:foo, nil, true)
      register_guest(:bar, :foo, true)

      subject.detect!
    end

    it "doesn't have unknown capabilities" do
      subject.capability?(:what_is_this_i_dont_even).should_not be
    end

    it "doesn't have capabilities registered to other guests" do
      register_capability(:baz, :test)

      subject.capability?(:test).should_not be
    end

    it "has capability of detected guest" do
      register_capability(:bar, :test)

      subject.capability?(:test).should be
    end

    it "has capability of parent guests" do
      register_capability(:foo, :test)

      subject.capability?(:test).should be
    end
  end

  describe "#detect!" do
    it "detects the first match" do
      register_guest(:foo, nil, false)
      register_guest(:bar, nil, true)
      register_guest(:baz, nil, false)

      subject.detect!
      subject.name.should == :bar
      subject.chain.length.should == 1
      subject.chain[0][0].should == :bar
      subject.chain[0][1].name.should == :bar
    end

    it "detects those with the most parents first" do
      register_guest(:foo, nil, true)
      register_guest(:bar, :foo, true)
      register_guest(:baz, :bar, true)
      register_guest(:foo2, nil, true)
      register_guest(:bar2, :foo2, true)

      subject.detect!
      subject.name.should == :baz
      subject.chain.length.should == 3
      subject.chain.map(&:first).should == [:baz, :bar, :foo]
      subject.chain.map { |x| x[1] }.map(&:name).should == [:baz, :bar, :foo]
    end

    it "detects the forced guest setting" do
      register_guest(:foo, nil, false)
      register_guest(:bar, nil, false)

      machine.config.vm.stub(:guest => :bar)

      subject.detect!
      subject.name.should == :bar
    end

    it "raises an exception if no guest can be detected" do
      expect { subject.detect! }.
        to raise_error(Vagrant::Errors::GuestNotDetected)
    end
  end

  describe "#ready?" do
    before(:each) do
      register_guest(:foo, nil, true)
    end

    it "should not be ready by default" do
      subject.ready?.should_not be
    end

    it "should be ready after detecting" do
      subject.detect!
      subject.ready?.should be
    end
  end
end
