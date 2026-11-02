# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/trigger")

describe VagrantPlugins::Kernel_V2::TriggerConfig do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  def assert_invalid
    errors = subject.validate(machine)
    if !errors.values.any? { |v| !v.empty? }
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.values.all? { |v| v.empty? }
      raise "Errors: #{errors.inspect}"
    end
  end

  before do
    env = double("env")
    allow(env).to receive(:root_path).and_return(nil)
    allow(machine).to receive(:env).and_return(env)
    allow(machine).to receive(:provider_config).and_return(nil)
    allow(machine).to receive(:provider_options).and_return({})
  end

  it "is valid with test defaults" do
    subject.finalize!
    assert_valid
  end

  let (:hash_block) { {info: "hi", run: {inline: "echo 'hi'"}} }
  let (:splat) { [:up, :destroy, :halt] }
  let (:arr) { [[:up, :destroy, :halt]] }

  describe "creating a before trigger" do
    it "creates a trigger with the splat syntax" do
      subject.before(:up, hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(1)
      expect(bf_trigger.first).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "creates a trigger with the array syntax" do
      subject.before([:up], hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(1)
      expect(bf_trigger.first).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "creates a trigger with the block syntax" do
      subject.before :up do |trigger|
        trigger.name = "rspec"
      end
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(1)
      expect(bf_trigger.first).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "creates multiple triggers with the splat syntax" do
      subject.before(splat, hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(3)
      bf_trigger.map { |t| expect(t).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger) }
    end

    it "creates multiple triggers with the block syntax" do
      subject.before splat do |trigger|
        trigger.name = "rspec"
      end
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(3)
      bf_trigger.map { |t| expect(t).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger) }
    end

    it "creates multiple triggers with the array syntax" do
      subject.before(arr, hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(3)
      bf_trigger.map { |t| expect(t).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger) }
    end
  end

  describe "creating an after trigger" do
    it "creates a trigger with the splat syntax" do
      subject.after(:up, hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(1)
      expect(af_trigger.first).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "creates a trigger with the array syntax" do
      subject.after([:up], hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(1)
      expect(af_trigger.first).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "creates a trigger with the block syntax" do
      subject.after :up do |trigger|
        trigger.name = "rspec"
      end
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(1)
      expect(af_trigger.first).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "creates multiple triggers with the splat syntax" do
      subject.after(splat, hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(3)
      af_trigger.map { |t| expect(t).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger) }
    end

    it "creates multiple triggers with the block syntax" do
      subject.after splat do |trigger|
        trigger.name = "rspec"
      end
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(3)
      af_trigger.map { |t| expect(t).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger) }
    end

    it "creates multiple triggers with the array syntax" do
      subject.after(arr, hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(3)
      af_trigger.map { |t| expect(t).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger) }
    end
  end

  describe "#create_trigger" do
    let(:command) { :up }
    let(:hash_block) { {info: "hi", run: {inline: "echo 'hi'"}} }

    it "returns a new VagrantConfigTrigger object if given a hash" do
      trigger = subject.create_trigger(command, hash_block)
      expect(trigger).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end

    it "returns a new VagrantConfigTrigger object if given a block" do
      block = Proc.new { |b| b.info = "test"}

      trigger = subject.create_trigger(command, block)
      expect(trigger).to be_a(VagrantPlugins::Kernel_V2::VagrantConfigTrigger)
    end
  end

  describe "#merge" do
    it "merges defined triggers" do
      a = described_class.new()
      b = described_class.new()

      a.before(splat, hash_block)
      a.after(arr, hash_block)
      b.before(splat, hash_block)
      b.after(arr, hash_block)

      result = a.merge(b)
      bf_trigger = result.instance_variable_get(:@_before_triggers)
      af_trigger = result.instance_variable_get(:@_after_triggers)

      expect(bf_trigger).to be_a(Array)
      expect(af_trigger).to be_a(Array)
      expect(bf_trigger.size).to eq(6)
      expect(af_trigger.size).to eq(6)
    end

    it "merges the other triggers if a class is empty" do
      a = described_class.new()
      b = described_class.new()

      a.before(splat, hash_block)
      a.after(arr, hash_block)

      b_bf_trigger = b.instance_variable_get(:@_before_triggers)
      b_af_trigger = b.instance_variable_get(:@_after_triggers)

      result = a.merge(b)
      bf_trigger = result.instance_variable_get(:@_before_triggers)
      af_trigger = result.instance_variable_get(:@_after_triggers)

      expect(bf_trigger.size).to eq(3)
      expect(af_trigger.size).to eq(3)
    end
  end
end
