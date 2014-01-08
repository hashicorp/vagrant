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
