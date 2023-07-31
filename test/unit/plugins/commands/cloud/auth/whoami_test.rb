# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/whoami")

describe VagrantPlugins::CloudCommand::AuthCommand::Command::Whoami do
  include_context "unit"

  let(:argv)     { [] }
  let(:env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end
  let(:client) { double("client", token: token) }
  let(:token) { double("token") }
  let(:account_username) { "account-username" }
  let(:account) { double("account", username: account_username) }
  let(:action_runner) { double("action_runner") }

  subject { described_class.new(argv, env) }

  before do
    allow(env).to receive(:action_runner).and_return(action_runner)
    allow(VagrantPlugins::CloudCommand::Client).to receive(:new).and_return(client)
    allow(VagrantCloud::Account).to receive(:new).and_return(account)
  end

  describe "whoami" do
    context "when token is unset" do
      let(:token) { "" }

      it "should output an error" do
        expect(env.ui).to receive(:error)
        subject.whoami(token)
      end

      it "should return non-zero" do
        r = subject.whoami(token)
        expect(r).not_to eq(0)
        expect(r).to be_a(Integer)
      end
    end

    context "when token is set" do
      let(:token) { "my-token" }

      it "should load an account to validate" do
        expect(VagrantCloud::Account).to receive(:new).
          with(hash_including(access_token: token)).and_return(account)
        subject.whoami(token)
      end

      it "should output the account username" do
        expect(env.ui).to receive(:success).with(/#{account_username}/)
        subject.whoami(token)
      end

      it "should return zero value" do
        expect(subject.whoami(token)).to eq(0)
      end

      context "when error is encountered" do
        before { allow(VagrantCloud::Account).to receive(:new).and_raise(VagrantCloud::Error::ClientError) }

        it "should output an error" do
          expect(env.ui).to receive(:error).twice
          subject.execute
        end

        it "should return a non-zero value" do
          r = subject.execute
          expect(r).not_to eq(0)
          expect(r).to be_a(Integer)
        end
      end
    end
  end

  describe "#execute" do
    before do
      allow(subject).to receive(:whoami)
    end

    context "with too many arguments" do
      let(:argv) { ["token", "token", "token"] }
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with no argument" do
      it "should use stored token via client" do
        expect(subject).to receive(:whoami).with(token)
        subject.execute
      end
    end

    context "with token argument" do
      let(:token_arg) { "TOKEN_ARG" }
      let(:argv) { [token_arg] }

      it "should use the passed token" do
        expect(subject).to receive(:whoami).with(token_arg)
        subject.execute
      end
    end
  end
end
