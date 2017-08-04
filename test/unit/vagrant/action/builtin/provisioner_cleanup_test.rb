require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::ProvisionerCleanup do
  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine, ui: ui } }

  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:config).and_return(machine_config)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |config|
      allow(config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config") }

  let(:ui) do
    double("ui").tap do |result|
      allow(result).to receive(:info)
    end
  end

  let(:provisioner) do
    Class.new(Vagrant.plugin("2", :provisioner))
  end

  before do
    allow_any_instance_of(described_class).to receive(:provisioner_type_map)
      .and_return(provisioner => :test_provisioner)
    allow_any_instance_of(described_class).to receive(:provisioner_instances)
      .and_return([provisioner])
  end

  describe "initialize with :before" do
    it "runs cleanup before" do
      instance = described_class.new(app, env, :before)
      expect(provisioner).to receive(:cleanup).ordered
      expect(app).to receive(:call).ordered
      instance.call(env)
    end
  end

  describe "initialize with :after" do
    it "runs cleanup after" do
      instance = described_class.new(app, env, :after)
      expect(app).to receive(:call).ordered
      expect(provisioner).to receive(:cleanup).ordered
      instance.call(env)
    end
  end

  it "only runs cleanup tasks if the subclass defines it" do
    parent = Class.new do
      class_variable_set(:@@cleanup, false)

      def self.called?
        class_variable_get(:@@cleanup)
      end

      def cleanup
        self.class.class_variable_set(:@@cleanup)
      end
    end

    child = Class.new(parent)

    allow_any_instance_of(described_class).to receive(:provisioner_type_map)
      .and_return(child => :test_provisioner)
    allow_any_instance_of(described_class).to receive(:provisioner_instances)
      .and_return([child])

    expect(parent.called?).to be(false)
    instance = described_class.new(app, env)
    instance.call(env)
    expect(parent.called?).to be(false)
  end
end
