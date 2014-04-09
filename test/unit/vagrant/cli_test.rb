require_relative "../base"

require "vagrant/cli"

describe Vagrant::CLI do
  include_context "unit"
  include_context "command plugin helpers"

  let(:commands) { {} }
  let(:iso_env) { isolated_environment }
  let(:env)     { iso_env.create_vagrant_env }

  before do
    Vagrant.plugin("2").manager.stub(commands: commands)
  end

  describe "#execute" do
    it "invokes help and exits with 1 if invalid command" do
      subject = described_class.new(["i-dont-exist"], env)
      expect(subject).to receive(:help).once
      expect(subject.execute).to eql(1)
    end

    it "invokes command and returns its exit status if the command is valid" do
      commands[:destroy] = [command_lambda("destroy", 42), {}]

      subject = described_class.new(["destroy"], env)
      expect(subject).not_to receive(:help)
      expect(subject.execute).to eql(42)
    end

    it "returns exit code 1 if interrupted" do
      commands[:destroy] = [command_lambda("destroy", 42, exception: Interrupt), {}]

      subject = described_class.new(["destroy"], env)
      expect(subject.execute).to eql(1)
    end
  end

  describe "#help" do
    subject { described_class.new([], env) }

    it "includes all primary subcommands" do
      commands[:foo] = [command_lambda("foo", 0), { primary: true }]
      commands[:bar] = [command_lambda("bar", 0), { primary: true }]
      commands[:baz] = [command_lambda("baz", 0), { primary: false }]

      expect(env.ui).to receive(:info).with { |message, opts|
        expect(message).to include("foo")
        expect(message).to include("bar")
        expect(message.include?("baz")).to be_false
      }

      subject.help
    end
  end
end
