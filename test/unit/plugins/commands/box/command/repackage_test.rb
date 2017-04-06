require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/box/command/repackage")

describe VagrantPlugins::CommandBox::Command::Repackage do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
  end

  context "with no arguments" do
    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "with one argument" do
    let(:argv) { ["one"] }

    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "with two arguments" do
    let(:argv) { ["one", "two"] }

    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "with three arguments" do
    it "repackages the box with the given provider"
  end

  context "with more than three arguments" do
    let(:argv) { ["one", "two", "three", "four"] }

    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end
end
