# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::Guest do
  include_context "capability_helpers"

  let(:capabilities) { {} }
  let(:guests)  { {} }
  let(:machine) do
    double("machine").tap do |m|
      allow(m).to receive(:inspect).and_return("machine")
      allow(m).to receive(:config).and_return(double("config"))
      allow(m.config).to receive(:vm).and_return(double("vm_config"))
      allow(m.config.vm).to receive(:guest).and_return(nil)
    end
  end

  subject { described_class.new(machine, guests, capabilities) }

  describe "#capability" do
    before(:each) do
      guests[:foo] = [detect_class(true), nil]
      capabilities[:foo] = {
        foo_cap: cap_instance(:foo_cap),
        corrupt_cap: cap_instance(:corrupt_cap, corrupt: true),
      }

      subject.detect!
    end

    it "executes existing capabilities" do
      expect { subject.capability(:foo_cap) }.
        to raise_error(RuntimeError, "cap: foo_cap [machine]")
    end

    it "raises user-friendly error for non-existing caps" do
      expect { subject.capability(:what_cap) }.
        to raise_error(Vagrant::Errors::GuestCapabilityNotFound)
    end

    it "raises a user-friendly error for corrupt caps" do
      expect { subject.capability(:corrupt_cap) }.
        to raise_error(Vagrant::Errors::GuestCapabilityInvalid)
    end
  end

  describe "#detect!" do
    it "auto-detects if no explicit guest name given" do
      allow(machine.config.vm).to receive(:guest).and_return(nil)
      expect(subject).to receive(:initialize_capabilities!).
        with(nil, guests, capabilities, machine)

      subject.detect!
    end

    it "uses the explicit guest name if specified" do
      allow(machine.config.vm).to receive(:guest).and_return(:foo)
      expect(subject).to receive(:initialize_capabilities!).
        with(:foo, guests, capabilities, machine)

      subject.detect!
    end

    it "raises a user-friendly error if specified guest doesn't exist" do
      allow(machine.config.vm).to receive(:guest).and_return(:foo)

      expect { subject.detect! }.
        to raise_error(Vagrant::Errors::GuestExplicitNotDetected)
    end

    it "raises a user-friendly error if auto-detected guest not found" do
      expect { subject.detect! }.
        to raise_error(Vagrant::Errors::GuestNotDetected)
    end
  end

  describe "#name" do
    it "should be the name of the detected guest" do
      guests[:foo] = [detect_class(true), nil]
      guests[:bar] = [detect_class(false), nil]

      subject.detect!
      expect(subject.name).to eql(:foo)
    end
  end

  describe "#ready?" do
    before(:each) do
      guests[:foo] = [detect_class(true), nil]
    end

    it "should not be ready by default" do
      expect(subject.ready?).not_to be
    end

    it "should be ready after detecting" do
      subject.detect!
      expect(subject.ready?).to be
    end
  end
end
