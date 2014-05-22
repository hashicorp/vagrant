require File.expand_path("../../../../base", __FILE__)
require 'optparse'

describe Vagrant::Plugin::V1::Command do
  describe "parsing options" do
    let(:klass) do
      Class.new(described_class) do
        # Make the method public since it is normally protected
        public :parse_options
      end
    end

    it "returns the remaining arguments" do
      options = {}
      opts = OptionParser.new do |opts|
        opts.on("-f") do |f|
          options[:f] = f
        end
      end

      result = klass.new(["-f", "foo"], nil).parse_options(opts)

      # Check the results
      expect(options[:f]).to be
      expect(result).to eq(["foo"])
    end

    it "creates an option parser if none is given" do
      result = klass.new(["foo"], nil).parse_options(nil)
      expect(result).to eq(["foo"])
    end

    ["-h", "--help"].each do |help_string|
      it "returns nil and prints the help if '#{help_string}' is given" do
        instance = klass.new([help_string], nil)
        expect(instance).to receive(:safe_puts)
        expect(instance.parse_options(OptionParser.new)).to be_nil
      end
    end

    it "raises an error if invalid options are given" do
      instance = klass.new(["-f"], nil)
      expect { instance.parse_options(OptionParser.new) }.
        to raise_error(Vagrant::Errors::CLIInvalidOptions)
    end
  end

  describe "target VMs" do
    let(:klass) do
      Class.new(described_class) do
        # Make the method public since it is normally protected
        public :with_target_vms
      end
    end

    let(:environment) do
      env = double("environment")
      env.stub(root_path: "foo")
      env
    end

    let(:instance)    { klass.new([], environment) }

    it "should raise an exception if a root_path is not available" do
      environment.stub(root_path: nil)

      expect { instance.with_target_vms }.
        to raise_error(Vagrant::Errors::NoEnvironmentError)
    end

    it "should yield every VM in order is no name is given" do
      foo_vm = double("foo")
      allow(foo_vm).to receive(:name).and_return("foo")

      bar_vm = double("bar")
      allow(bar_vm).to receive(:name).and_return("bar")

      environment.stub(multivm?: true,
                       vms: { "foo" => foo_vm, "bar" => bar_vm },
                       vms_ordered: [foo_vm, bar_vm])

      vms = []
      instance.with_target_vms do |vm|
        vms << vm
      end

      expect(vms).to eq([foo_vm, bar_vm])
    end

    it "raises an exception if the named VM doesn't exist" do
      environment.stub(multivm?: true, vms: {})

      expect { instance.with_target_vms("foo") }.
        to raise_error(Vagrant::Errors::VMNotFoundError)
    end

    it "yields the given VM if a name is given" do
      foo_vm = double("foo")
      allow(foo_vm).to receive(:name).and_return(:foo)

      environment.stub(multivm?: true,
                       vms: { foo: foo_vm, bar: nil })

      vms = []
      instance.with_target_vms("foo") { |vm| vms << vm }
      expect(vms).to eq([foo_vm])
    end
  end

  describe "splitting the main and subcommand args" do
    let(:instance) do
      Class.new(described_class) do
        # Make the method public since it is normally protected
        public :split_main_and_subcommand
      end.new(nil, nil)
    end

    it "should work when given all 3 parts" do
      result = instance.split_main_and_subcommand(["-v", "status", "-h", "-v"])
      expect(result).to eq([["-v"], "status", ["-h", "-v"]])
    end

    it "should work when given only a subcommand and args" do
      result = instance.split_main_and_subcommand(["status", "-h"])
      expect(result).to eq([[], "status", ["-h"]])
    end

    it "should work when given only main flags" do
      result = instance.split_main_and_subcommand(["-v", "-h"])
      expect(result).to eq([["-v", "-h"], nil, []])
    end

    it "should work when given only a subcommand" do
      result = instance.split_main_and_subcommand(["status"])
      expect(result).to eq([[], "status", []])
    end

    it "works when there are other non-flag args after the subcommand" do
      result = instance.split_main_and_subcommand(["-v", "box", "add", "-h"])
      expect(result).to eq([["-v"], "box", ["add", "-h"]])
    end
  end
end
