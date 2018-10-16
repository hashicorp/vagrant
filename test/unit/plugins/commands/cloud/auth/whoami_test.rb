require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/whoami")

describe VagrantPlugins::CloudCommand::AuthCommand::Command::Whoami do
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

  let(:client) { double("client", token: "1234token1234") }
  let(:account) { double("account") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
    allow(VagrantPlugins::CloudCommand::Util).to receive(:client_login).
      and_return(client)
    allow(VagrantPlugins::CloudCommand::Util).to receive(:account).
      and_return(account)
  end

  context "with too many arguments" do
    let(:argv) { ["token", "token", "token"] }
    it "shows help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "with username" do
    let(:argv) { ["token"] }
    let(:org_hash) { {"user"=>{"username"=>"mario"}, "boxes"=>[{"name"=>"box"}]} }

    it "gets information about a user" do
      expect(account).to receive(:validate_token).and_return(org_hash)
      expect(subject.execute).to eq(0)
    end

    it "returns 1 if encountering an error making request" do
      allow(account).to receive(:validate_token).
        and_raise(VagrantCloud::ClientError.new("Fail Message", "Message", 404))
      expect(subject.execute).to eq(1)
    end
  end
end
