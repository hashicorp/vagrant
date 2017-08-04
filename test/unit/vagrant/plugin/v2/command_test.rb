require File.expand_path("../../../../base", __FILE__)
require 'optparse'

describe Vagrant::Plugin::V2::Command do
  include_context "unit"

  describe "parsing options" do
    let(:klass) do
      Class.new(described_class) do
        # Make the method public since it is normally protected
        public :parse_options
      end
    end

    it "returns the remaining arguments" do
      options = {}
      opts = OptionParser.new do |o|
        o.on("-f") do |f|
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

    it "raises an error if options without a value are given" do
      opts = OptionParser.new do |o|
        o.on("--provision-with x,y,z", Array, "Example") { |f| }
      end


      instance = klass.new(["--provision-with"], nil)
      expect { instance.parse_options(opts) }.
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
      # We have to create a Vagrantfile so there is a root path
      test_iso_env.vagrantfile("")
      test_iso_env.create_vagrant_env
    end
    let(:test_iso_env) { isolated_environment }

    let(:instance)    { klass.new([], environment) }

    subject { instance }

    it "should raise an exception if a root_path is not available" do
      allow(environment).to receive(:root_path).and_return(nil)

      expect { instance.with_target_vms }.
        to raise_error(Vagrant::Errors::NoEnvironmentError)
    end

    it "should yield every VM in order if no name is given" do
      foo_vm = double("foo")
      allow(foo_vm).to receive(:name).and_return("foo")
      allow(foo_vm).to receive(:provider).and_return(:foobarbaz)
      allow(foo_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(foo_vm).to receive(:state).and_return(nil)

      bar_vm = double("bar")
      allow(bar_vm).to receive(:name).and_return("bar")
      allow(bar_vm).to receive(:provider).and_return(:foobarbaz)
      allow(bar_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(bar_vm).to receive(:state).and_return(nil)

      allow(environment).to receive(:machine_names).and_return([:foo, :bar])
      allow(environment).to receive(:machine).with(:foo, environment.default_provider).and_return(foo_vm)
      allow(environment).to receive(:machine).with(:bar, environment.default_provider).and_return(bar_vm)

      vms = []
      instance.with_target_vms do |vm|
        vms << vm
      end

      expect(vms).to eq([foo_vm, bar_vm])
    end

    it "raises an exception if the named VM doesn't exist" do
      allow(environment).to receive(:machine_names).and_return([:default])
      allow(environment).to receive(:machine).with(:foo, anything).and_return(nil)

      expect { instance.with_target_vms("foo") }.
        to raise_error(Vagrant::Errors::VMNotFoundError)
    end

    it "yields the given VM if a name is given" do
      foo_vm = double("foo")
      allow(foo_vm).to receive(:name).and_return("foo")
      allow(foo_vm).to receive(:provider).and_return(:foobarbaz)
      allow(foo_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(foo_vm).to receive(:state).and_return(nil)

      allow(environment).to receive(:machine).with(:foo, environment.default_provider).and_return(foo_vm)

      vms = []
      instance.with_target_vms("foo") { |vm| vms << vm }
      expect(vms).to eq([foo_vm])
    end

    it "calls state after yielding the vm to update the machine index" do
      foo_vm = double("foo")
      allow(foo_vm).to receive(:name).and_return("foo")
      allow(foo_vm).to receive(:provider).and_return(:foobarbaz)
      allow(foo_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(foo_vm).to receive(:state).and_return(nil)

      allow(environment).to receive(:machine).with(:foo, environment.default_provider).and_return(foo_vm)

      vms = []
      expect(foo_vm).to receive(:state)
      instance.with_target_vms("foo") { |vm| vms << vm }
    end

    it "yields the given VM with proper provider if given" do
      foo_vm = double("foo")
      provider = :foobarbaz

      allow(foo_vm).to receive(:name).and_return("foo")
      allow(foo_vm).to receive(:provider).and_return(provider)
      allow(foo_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(foo_vm).to receive(:state).and_return(nil)
      allow(environment).to receive(:machine).with(:foo, provider).and_return(foo_vm)

      vms = []
      instance.with_target_vms("foo", provider: provider) { |vm| vms << vm }
      expect(vms).to eq([foo_vm])
    end

    it "should raise an exception if an active machine exists with a different provider" do
      name = :foo

      allow(environment).to receive(:active_machines).and_return([[name, :vmware]])
      expect { instance.with_target_vms(name.to_s, provider: :foo) }.
        to raise_error Vagrant::Errors::ActiveMachineWithDifferentProvider
    end

    it "should default to the active machine provider if no explicit provider requested" do
      name = :foo
      provider = :vmware
      vmware_vm = double("vmware_vm")

      allow(environment).to receive(:active_machines).and_return([[name, provider]])
      allow(environment).to receive(:machine).with(name, provider).and_return(vmware_vm)
      allow(vmware_vm).to receive(:name).and_return(name)
      allow(vmware_vm).to receive(:provider).and_return(provider)
      allow(vmware_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(vmware_vm).to receive(:state).and_return(nil)

      vms = []
      instance.with_target_vms(name.to_s) { |vm| vms << vm }
      expect(vms).to eq([vmware_vm])
    end

    it "should use the explicit provider if it maches the active machine" do
      name = :foo
      provider = :vmware
      vmware_vm = double("vmware_vm")

      allow(environment).to receive(:active_machines).and_return([[name, provider]])
      allow(environment).to receive(:machine).with(name, provider).and_return(vmware_vm)
      allow(vmware_vm).to receive(:name).and_return(name)
      allow(vmware_vm).to receive(:provider).and_return(provider)
      allow(vmware_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(vmware_vm).to receive(:state).and_return(nil)

      vms = []
      instance.with_target_vms(name.to_s, provider: provider) { |vm| vms << vm }
      expect(vms).to eq([vmware_vm])
    end

    it "should use the default provider if none is given and none are active" do
      name = :foo
      machine = double("machine")

      allow(environment).to receive(:machine).with(name, environment.default_provider).and_return(machine)
      allow(machine).to receive(:name).and_return(name)
      allow(machine).to receive(:provider).and_return(environment.default_provider)
      allow(machine).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(machine).to receive(:state).and_return(nil)

      results = []
      instance.with_target_vms(name.to_s) { |m| results << m }
      expect(results).to eq([machine])
    end

    it "should use the primary machine with the active provider" do
      name = :foo
      provider = :vmware
      vmware_vm = double("vmware_vm")

      allow(environment).to receive(:active_machines).and_return([[name, provider]])
      allow(environment).to receive(:machine).with(name, provider).and_return(vmware_vm)
      allow(environment).to receive(:machine_names).and_return([])
      allow(environment).to receive(:primary_machine_name).and_return(name)
      allow(vmware_vm).to receive(:name).and_return(name)
      allow(vmware_vm).to receive(:provider).and_return(provider)
      allow(vmware_vm).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(vmware_vm).to receive(:state).and_return(nil)

      vms = []
      instance.with_target_vms(nil, single_target: true) { |vm| vms << vm }
      expect(vms).to eq([vmware_vm])
    end

    it "should use the primary machine with the default provider" do
      name = :foo
      machine = double("machine")

      allow(environment).to receive(:active_machines).and_return([])
      allow(environment).to receive(:machine).with(name, environment.default_provider).and_return(machine)
      allow(environment).to receive(:machine_names).and_return([])
      allow(environment).to receive(:primary_machine_name).and_return(name)
      allow(machine).to receive(:name).and_return(name)
      allow(machine).to receive(:provider).and_return(environment.default_provider)
      allow(machine).to receive(:ui).and_return(Vagrant::UI::Silent.new)
      allow(machine).to receive(:state).and_return(nil)

      vms = []
      instance.with_target_vms(nil, single_target: true) { |vm| vms << machine }
      expect(vms).to eq([machine])
    end

    it "should yield machines from another environment" do
      iso_env       = isolated_environment
      iso_env.vagrantfile("")
      other_env     = iso_env.create_vagrant_env(
        home_path: environment.home_path)
      other_machine = other_env.machine(
        other_env.machine_names[0], other_env.default_provider)

      # Set an ID on it so that it is "created" in the index
      other_machine.id = "foo"

      # Make sure we don't have a root path, to test
      allow(environment).to receive(:root_path).and_return(nil)

      results = []
      subject.with_target_vms(other_machine.index_uuid) { |m| results << m }

      expect(results.length).to eq(1)
      expect(results[0].id).to eq(other_machine.id)
    end

    it "should yield machines from another environment" do
      iso_env       = isolated_environment
      iso_env.vagrantfile("")
      other_env     = iso_env.create_vagrant_env(
        home_path: environment.home_path)
      other_machine = other_env.machine(
        other_env.machine_names[0], other_env.default_provider)

      # Set an ID on it so that it is "created" in the index
      other_machine.id = "foo"

      # Grab the uuid so we know what it is
      index_uuid = other_machine.index_uuid

      # Remove the working directory
      FileUtils.rm_rf(iso_env.workdir)

      # Make sure we don't have a root path, to test
      allow(environment).to receive(:root_path).and_return(nil)

      # Run the command
      expect {
          subject.with_target_vms(index_uuid) { |*args| }
      }.to raise_error(Vagrant::Errors::EnvironmentNonExistentCWD)

      # Verify that it no longer exists in the index
      expect(other_env.machine_index.get(index_uuid)).to be_nil
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
