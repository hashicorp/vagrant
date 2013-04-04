require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::Guest do
  include_context "unit"

  let(:guests)  { {} }
  let(:machine) { double("machine") }

  subject { described_class.new(machine, guests) }

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

  describe "#detect!" do
    it "detects the first match" do
      register_guest(:foo, nil, false)
      register_guest(:bar, nil, true)
      register_guest(:baz, nil, false)

      subject.detect!
      subject.chain.length.should == 1
      subject.chain[0].name.should == :bar
    end

    it "detects those with the most parents first" do
      register_guest(:foo, nil, true)
      register_guest(:bar, :foo, true)
      register_guest(:baz, :bar, true)
      register_guest(:foo2, nil, true)
      register_guest(:bar2, :foo2, true)

      subject.detect!
      subject.chain.length.should == 3
      subject.chain.map(&:name).should == [:baz, :bar, :foo]
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
