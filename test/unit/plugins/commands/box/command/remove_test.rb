require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/box/command/remove")

describe VagrantPlugins::CommandBox::Command::Remove do
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
    iso_env.stub(action_runner: action_runner)
  end

  context "with no arguments" do
    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "with one argument" do
    let(:argv) { ["foo"] }

    it "invokes the action runner" do
      action_runner.should_receive(:run).with do |action, opts|
        expect(opts[:box_name]).to eq("foo")
        true
      end

      subject.execute
    end
  end

  context "with two arguments" do
    let(:argv) { ["foo", "bar"] }

    it "uses the 2nd arg as a provider" do
      action_runner.should_receive(:run).with do |action, opts|
        expect(opts[:box_name]).to eq("foo")
        expect(opts[:box_provider]).to eq("bar")
        true
      end

      subject.execute
    end
  end

  context "with more than two arguments" do
    let(:argv) { ["one", "two", "three"] }

    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end
end
