require File.expand_path("../../base", __FILE__)

require "pathname"
require "tmpdir"

require "vagrant/vagrantfile"

describe Vagrant::Vagrantfile do
  include_context "unit"

  let(:keys) { [] }
  let(:loader) {
    Vagrant::Config::Loader.new(
      Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
  }

  subject { described_class.new(loader, keys) }

  before do
    keys << :test
  end

  def configure(&block)
    loader.set(:test, [["2", block]])
  end

  # A helper to register a provider for use in tests.
  def register_provider(name, config_class=nil, options=nil)
    provider_cls = Class.new(VagrantTests::DummyProvider) do
      if options && options[:unusable]
        def self.usable?(raise_error=false)
          raise Vagrant::Errors::VagrantError if raise_error
          false
        end
      end
    end

    register_plugin("2") do |p|
      p.provider(name, options) { provider_cls }

      if config_class
        p.config(name, :provider) { config_class }
      end
    end

    provider_cls
  end

  describe "#config" do
    it "exposes the global configuration" do
      configure do |config|
        config.vm.box = "what"
      end

      expect(subject.config.vm.box).to eq("what")
    end
  end

  describe "#machine" do
    let(:boxes) { Vagrant::BoxCollection.new(iso_env.boxes_dir) }
    let(:data_path) { Pathname.new(Dir.mktmpdir("vagrant-machine-data-path")) }
    let(:env)   { iso_env.create_vagrant_env }
    let(:iso_env) { isolated_environment }
    let(:vagrantfile) { described_class.new(loader, keys) }

    subject { vagrantfile.machine(:default, :foo, boxes, data_path, env) }

    before do
      @foo_config_cls = Class.new(Vagrant.plugin("2", "config")) do
        attr_accessor :value
      end

      @provider_cls = register_provider("foo", @foo_config_cls)

      configure do |config|
        config.vm.box = "foo"
        config.vm.provider "foo" do |p|
          p.value = "rawr"
        end
      end

      iso_env.box3("foo", "1.0", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF
    end

    after do
      FileUtils.rm_rf(data_path.to_s)
    end

    describe '#data_dir' do
      subject { super().data_dir }
      it { should eq(data_path) }
    end

    describe '#env' do
      subject { super().env }
      it      { should equal(env)    }
    end

    describe '#name' do
      subject { super().name }
      it     { should eq(:default)  }
    end

    describe '#provider' do
      subject { super().provider }
      it { should be_kind_of(@provider_cls) }
    end

    describe '#provider_name' do
      subject { super().provider_name }
      it { should eq(:foo) }
    end

    describe '#vagrantfile' do
      subject { super().vagrantfile }
      it { should equal(vagrantfile) }
    end

    it "has the proper box" do
      expect(subject.box.name).to eq("foo")
    end

    it "has the valid configuration" do
      expect(subject.config.vm.box).to eq("foo")
    end

    it "loads the provider-specific configuration" do
      expect(subject.provider_config).to be_kind_of(@foo_config_cls)
      expect(subject.provider_config.value).to eq("rawr")
    end
  end

  describe "#machine_config" do
    let(:iso_env) { isolated_environment }
    let(:boxes) { Vagrant::BoxCollection.new(iso_env.boxes_dir) }

    it "should return a basic configured machine" do
      provider_cls = register_provider("foo")

      configure do |config|
        config.vm.box = "foo"
      end

      results = subject.machine_config(:default, :foo, boxes)
      box     = results[:box]
      config  = results[:config]
      expect(config.vm.box).to eq("foo")
      expect(box).to be_nil
      expect(results[:provider_cls]).to equal(provider_cls)
    end

    it "configures without a provider or boxes" do
      register_provider("foo")

      configure do |config|
        config.vm.box = "foo"
      end

      results = subject.machine_config(:default, nil, nil)
      box     = results[:box]
      config  = results[:config]
      expect(config.vm.box).to eq("foo")
      expect(box).to be_nil
      expect(results[:provider_cls]).to be_nil
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

      results = subject.machine_config(:foo, :foo, boxes)
      config  = results[:config]
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(100)
    end

    it "configures with box configuration if it exists" do
      register_provider("foo")

      configure do |config|
        config.vm.box = "base"
      end

      iso_env.box3("base", "1.0", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      results = subject.machine_config(:default, :foo, boxes)
      box     = results[:box]
      config  = results[:config]
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(123)
      expect(box).to_not be_nil
      expect(box.name).to eq("base")
    end

    it "configures with the proper box version" do
      register_provider("foo")

      configure do |config|
        config.vm.box = "base"
        config.vm.box_version = "~> 1.2"
      end

      iso_env.box3("base", "1.0", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      iso_env.box3("base", "1.3", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 245
      end
      VF

      results = subject.machine_config(:default, :foo, boxes)
      box     = results[:box]
      config  = results[:config]
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(245)
      expect(box).to_not be_nil
      expect(box.name).to eq("base")
      expect(box.version).to eq("1.3")
    end

    it "configures with box config of other supported formats" do
      register_provider("foo", nil, box_format: "bar")

      configure do |config|
        config.vm.box = "base"
      end

      iso_env.box3("base", "1.0", :bar, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      results = subject.machine_config(:default, :foo, boxes)
      config  = results[:config]
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
      results = subject.machine_config(:default, :foo, boxes)
      config  = results[:config]
      expect(config.vm.box).to eq("base")
      expect(config.ssh.port).to eq(100)

      # Test without the override
      results = subject.machine_config(:default, :bar, boxes)
      config  = results[:config]
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

      iso_env.box3("base", "1.0", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 123
      end
      VF

      iso_env.box3("foobox", "1.0", :foo, vagrantfile: <<-VF)
      Vagrant.configure("2") do |config|
        config.ssh.port = 234
      end
      VF

      results = subject.machine_config(:default, :foo, boxes)
      config  = results[:config]
      box     = results[:box]
      expect(config.vm.box).to eq("foobox")
      expect(config.ssh.port).to eq(234)
      expect(box).to_not be_nil
      expect(box.name).to eq("foobox")
    end

    it "raises an error if the machine is not found" do
      expect { subject.machine_config(:foo, :foo, boxes) }.
        to raise_error(Vagrant::Errors::MachineNotFound)
    end

    it "raises an error if the provider is not found" do
      expect { subject.machine_config(:default, :foo, boxes) }.
        to raise_error(Vagrant::Errors::ProviderNotFound)
    end

    it "raises an error if the provider is not usable" do
      register_provider("foo", nil, unusable: true)

      expect { subject.machine_config(:default, :foo, boxes) }.
        to raise_error(Vagrant::Errors::ProviderNotUsable)
    end
  end

  describe "#machine_names" do
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

  describe "#machine_names_and_options" do
    it "returns the default name" do
      configure { |config| }

      expect(subject.machine_names_and_options).to eq({
        default: { config_version: "2" },
      })
    end

    it "returns all the machines" do
      configure do |config|
        config.vm.define "foo"
        config.vm.define "bar", autostart: false
        config.vm.define "baz", autostart: true
      end

      expect(subject.machine_names_and_options).to eq({
        foo: { config_version: "2" },
        bar: { config_version: "2", autostart: false },
        baz: { config_version: "2", autostart: true },
      })
    end
  end

  describe "#primary_machine_name" do
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
