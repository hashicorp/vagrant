require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::Guest do
  include_context "capability_helpers"

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

  describe "#detect!" do
    it "auto-detects if no explicit guest name given" do
      machine.config.vm.stub(guest: nil)
      subject.should_receive(:initialize_capabilities!).
        with(nil, guests, capabilities, machine)

      subject.detect!
    end

    it "uses the explicit guest name if specified" do
      machine.config.vm.stub(guest: :foo)
      subject.should_receive(:initialize_capabilities!).
        with(:foo, guests, capabilities, machine)

      subject.detect!
    end
  end

  describe "#ready?" do
    before(:each) do
      guests[:foo] = [detect_class(true), nil]
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
