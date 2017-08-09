require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/list-commands/command")

describe VagrantPlugins::CommandListCommands::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:argv)     { [] }
  let(:commands) { {} }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(Vagrant.plugin("2").manager).to receive(:commands).and_return(commands)
  end

  describe "execute" do
    it "includes all subcommands" do
      commands[:foo] = [command_lambda("foo", 0), { primary: true }]
      commands[:bar] = [command_lambda("bar", 0), { primary: true }]
      commands[:baz] = [command_lambda("baz", 0), { primary: false }]

      expect(iso_env.ui).to receive(:info).with(any_args) { |message, opts|
        expect(message).to include("foo")
        expect(message).to include("bar")
        expect(message).to include("baz")
      }

      subject.execute
    end
  end
end
