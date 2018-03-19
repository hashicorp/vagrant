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
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.before(:up, hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(1)
    end

    it "creates a trigger with the array syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.before([:up], hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(1)
    end

    it "creates a trigger with the block syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.before :up do |trigger|
        trigger.name = "rspec"
      end
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(1)
    end

    it "creates multiple triggers with the splat syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.before(splat, hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(3)
    end

    it "creates multiple triggers with the block syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.before splat do |trigger|
        trigger.name = "rspec"
      end
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(3)
    end

    it "creates multiple triggers with the array syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.before(arr, hash_block)
      bf_trigger = subject.instance_variable_get(:@_before_triggers)
      expect(bf_trigger.size).to eq(3)
    end
  end

  describe "creating an after trigger" do
    it "creates a trigger with the splat syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.after(:up, hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(1)
    end

    it "creates a trigger with the array syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.after([:up], hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(1)
    end

    it "creates a trigger with the block syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.after :up do |trigger|
        trigger.name = "rspec"
      end
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(1)
    end

    it "creates multiple triggers with the splat syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.after(splat, hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(3)
    end

    it "creates multiple triggers with the block syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.after splat do |trigger|
        trigger.name = "rspec"
      end
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(3)
    end

    it "creates multiple triggers with the array syntax" do
      allow(subject).to receive(:create_trigger).and_return([:foo])
      subject.after(arr, hash_block)
      af_trigger = subject.instance_variable_get(:@_after_triggers)
      expect(af_trigger.size).to eq(3)
    end
  end
end
