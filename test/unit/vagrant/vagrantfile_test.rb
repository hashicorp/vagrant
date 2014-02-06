require File.expand_path("../../base", __FILE__)

require "vagrant/vagrantfile"

describe Vagrant::Vagrantfile do
  include_context "unit"

  let(:keys) { [] }
  let(:loader) {
    Vagrant::Config::Loader.new(
      Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
  }

  subject { described_class.new(loader, keys) }

  describe "#machine_config" do
    let(:iso_env) { isolated_environment }
    let(:boxes) { Vagrant::BoxCollection.new(iso_env.boxes_dir) }

    before do
      keys << :test
    end

    def configure(&block)
      loader.set(:test, [["2", block]])
    end

    # A helper to register a provider for use in tests.
    def register_provider(name, config_class=nil, options=nil)
      provider_cls = Class.new(Vagrant.plugin("2", :provider))

      register_plugin("2") do |p|
        p.provider(name, options) { provider_cls }

        if config_class
          p.config(name, :provider) { config_class }
        end
      end

      provider_cls
    end

    it "should return a basic configured machine" do
      register_provider("foo")

      configure do |config|
        config.vm.box = "foo"
      end

      config, _ = subject.machine_config(:default, :foo, boxes)
      expect(config.vm.box).to eq("foo")
    end

    it "configures with sub-machine config" do
      register_provider("foo")

      configure do |config|
        config.ssh.port = "1"
        config.vm.box = "base"

        config.vm.define "foo" do |f|
          f.ssh.port = 100
        end
      end

      config, _ = subject.machine_config(:foo, :foo, boxes)
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(100)
    end

    it "configures with box configuration if it exists" do
      register_provider("foo")

      configure do |config|
        config.vm.box = "base"
      end

      iso_env.box2("base", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      config, _ = subject.machine_config(:default, :foo, boxes)
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(123)
    end

    it "configures with box config of other supported formats" do
      register_provider("foo", nil, box_format: "bar")

      configure do |config|
        config.vm.box = "base"
      end

      iso_env.box2("base", :bar, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      config, _ = subject.machine_config(:default, :foo, boxes)
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(123)
    end

    it "loads provider overrides if set" do
      register_provider("foo")
      register_provider("bar")

      configure do |config|
        config.ssh.port = 1
        config.vm.box = "base"

        config.vm.provider "foo" do |_, c|
          c.ssh.port = 100
        end
      end

      # Test with the override
      config, _ = subject.machine_config(:default, :foo, boxes)
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(100)

      # Test without the override
      config, _ = subject.machine_config(:default, :bar, boxes)
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(1)
    end

    it "loads the proper box if in a provider override" do
      register_provider("foo")

      configure do |config|
        config.vm.box = "base"

        config.vm.provider "foo" do |_, c|
          c.vm.box = "foobox"
        end
      end

      iso_env.box2("base", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      iso_env.box2("foobox", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 234
      end
      VF

      config, _ = subject.machine_config(:default, :foo, boxes)
      expect(config.vm.box).to eq("foobox")
      expect(config.ssh.port).to eq(234)
    end

    it "raises an error if the machine is not found" do
      expect { subject.machine_config(:foo, :foo, boxes) }.
        to raise_error(Vagrant::Errors::MachineNotFound)
    end

    it "raises an error if the provider is not found" do
      expect { subject.machine_config(:default, :foo, boxes) }.
        to raise_error(Vagrant::Errors::ProviderNotFound)
    end
  end

  describe "#machine_names" do
    before do
      keys << :test
    end

    def configure(&block)
      loader.set(:test, [["2", block]])
    end

    it "returns the default name when single-VM" do
      configure { |config| }

      expect(subject.machine_names).to eq([:default])
    end

    it "returns all of the names in a multi-VM" do
      configure do |config|
        config.vm.define "foo"
        config.vm.define "bar"
      end

      expect(subject.machine_names).to eq(
        [:foo, :bar])
    end
  end

  describe "#primary_machine_name" do
    before do
      keys << :test
    end

    def configure(&block)
      loader.set(:test, [["2", block]])
    end

    it "returns the default name when single-VM" do
      configure { |config| }

      expect(subject.primary_machine_name).to eq(:default)
    end

    it "returns the designated machine in multi-VM" do
      configure do |config|
        config.vm.define "foo"
        config.vm.define "bar", primary: true
        config.vm.define "baz"
      end

      expect(subject.primary_machine_name).to eq(:bar)
    end

    it "returns nil if no designation in multi-VM" do
      configure do |config|
        config.vm.define "foo"
        config.vm.define "baz"
      end

      expect(subject.primary_machine_name).to be_nil
    end
  end
end
