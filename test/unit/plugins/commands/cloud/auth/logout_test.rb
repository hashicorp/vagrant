# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/logout")

describe VagrantPlugins::CloudCommand::AuthCommand::Command::Logout do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end
  let(:client) { double("client") }

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    allow(VagrantPlugins::CloudCommand::Client).to receive(:new).and_return(client)
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
  end

  context "with any arguments" do
    let (:argv) { ["stuff", "things"] }

    it "shows the help" do
      expect { subject.execute }.
        to raise_error(Vagrant::Errors::CLIInvalidUsage)
    end
  end

  context "with no arguments" do
    it "logs you out" do
      expect(client).to receive(:clear_token)
      expect(subject.execute).to eq(0)
    end
  end
end
