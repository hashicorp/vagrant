require_relative "../../../base"
require_relative "../../../../../plugins/commands/package/command"

RSpec::Matchers.define :a_machine_named do |name|
  match{ |actual| actual.name.to_s == name.to_s }
end

RSpec::Matchers.define :an_existing_directory do
  match{ |actual| File.directory?(actual) }
end

describe VagrantPlugins::CommandPackage::Command do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:package_command) { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
  end

  describe "#execute" do

    context "with no arguments" do

      it "packages default machine" do
        expect(package_command).to receive(:package_vm).with(a_machine_named('default'), {})
        package_command.execute
      end
    end

    context "with single argument" do
      context "set to default" do

        let(:argv){ ['default'] }

        it "packages default machine" do
          expect(package_command).to receive(:package_vm).with(a_machine_named('default'), {})
          package_command.execute
        end
      end

      context "set to undefined vm" do

        let(:argv){ ['undefined'] }

        it "raises machine not found error" do
          expect{ package_command.execute }.to raise_error(Vagrant::Errors::MachineNotFound)
        end
      end

      context "with --output option" do

        let(:argv){ ['--output', 'package-output-folder/default'] }

        it "packages default machine inside specified folder" do
          expect(package_command).to receive(:package_vm).with(
            a_machine_named('default'), :output => "package-output-folder/default"
          )
          package_command.execute
        end
      end
    end

    context "with multiple arguments" do

      let(:argv){ ['default', 'undefined'] }

      it "ignores the extra arguments" do
        expect(package_command).to receive(:package_vm).with(a_machine_named('default'), {})
        package_command.execute
      end
    end

    context "with --base option" do
      context "and no option value" do

        let(:argv){ ['--base'] }

        it "shows help" do
          expect{ package_command.execute }.to raise_error(Vagrant::Errors::CLIInvalidOptions)
        end
      end

      context "and option value" do

        let(:argv){ ['--base', 'machine-id'] }

        it "packages vm defined within virtualbox" do
          expect(package_command).to receive(:package_base).with(:base => 'machine-id')
          package_command.execute
        end

        it "provides a machine data directory" do
          expect(Vagrant::Machine).to receive(:new).with(
            'machine-id', :virtualbox, anything, nil, anything, anything, an_existing_directory,
            anything, anything, anything, anything).and_return(double("vm", name: "machine-id"))
          allow(package_command).to receive(:package_vm)
          package_command.execute
        end
      end
    end

  end
end
