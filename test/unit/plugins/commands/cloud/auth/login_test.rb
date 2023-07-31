# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/auth/login")

describe VagrantPlugins::CloudCommand::AuthCommand::Command::Login do
  include_context "unit"

  let(:argv) { [] }
  let(:env)  { isolated_environment.create_vagrant_env }
  let(:action_runner) { double("action_runner") }
  let(:client) { double("client", logged_in?: logged_in) }
  let(:logged_in) { true }

  before do
    allow(env).to receive(:action_runner).
      and_return(action_runner)
    allow(VagrantPlugins::CloudCommand::Client).
      to receive(:new).and_return(client)
  end

  subject { described_class.new(argv, env) }

  describe "#execute_check" do
    context "when user is logged in" do
      let(:logged_in) { true }

      it "should output a success message" do
        expect(env.ui).to receive(:success)
        subject.execute_check(client)
      end

      it "should return zero value" do
        expect(subject.execute_check(client)).to eq(0)
      end
    end

    context "when user is not logged in" do
      let(:logged_in) { false }

      it "should output an error message" do
        expect(env.ui).to receive(:error)
        subject.execute_check(client)
      end

      it "should return a non-zero value" do
        r = subject.execute_check(client)
        expect(r).not_to eq(0)
        expect(r).to be_a(Integer)
      end
    end
  end

  describe "#execute_token" do
    let(:token) { double("token") }

    before { allow(client).to receive(:store_token) }

    it "should store the token" do
      expect(client).to receive(:store_token).with(token)
      subject.execute_token(client, token)
    end

    context "when token is valid" do
      let(:logged_in) { true }

      it "should output a success message" do
        expect(env.ui).to receive(:success).twice
        subject.execute_token(client, token)
      end

      it "should return a zero value" do
        expect(subject.execute_token(client, token)).to eq(0)
      end
    end

    context "when token is invalid" do
      let(:logged_in) { false }

      it "should output an error message" do
        expect(env.ui).to receive(:error)
        subject.execute_token(client, token)
      end

      it "should return a non-zero value" do
        r = subject.execute_token(client, token)
        expect(r).not_to eq(0)
        expect(r).to be_a(Integer)
      end
    end
  end

  describe "#execute" do
    before do
      allow(client).to receive(:username_or_email=)
      allow(client).to receive(:store_token)
    end

    context "when arguments are passed" do
      before { argv << "argument" }

      it "should print help" do
        expect { subject.execute }.to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "when --check flag is used" do
      before { argv << "--check" }

      it "should run login check" do
        expect(subject).to receive(:execute_check).with(client)
        subject.execute
      end

      it "should return the value of the check execution" do
        result = double("result")
        expect(subject).to receive(:execute_check).with(client).and_return(result)
        expect(subject.execute).to eq(result)
      end
    end

    context "when --token flag is used" do
      let(:new_token) { "NEW-TOKEN" }

      before { argv.push("--token").push(new_token) }

      it "should execute the token action" do
        expect(subject).to receive(:execute_token).with(client, new_token)
        subject.execute
      end

      it "should return value of token action" do
        result = double("result")
        expect(subject).to receive(:execute_token).with(client, new_token).and_return(result)
        expect(subject.execute).to eq(result)
      end

      it "should store the new token" do
        expect(client).to receive(:store_token).with(new_token)
        subject.execute
      end
    end

    context "when user is logged in" do
      let(:logged_in) { true }

      it "should output success message" do
        expect(env.ui).to receive(:success)
        subject.execute
      end

      it "should return a zero value" do
        expect(subject.execute).to eq(0)
      end
    end

    context "when user is not logged in" do
      let(:logged_in) { false }

      it "should run the client login" do
        expect(subject).to receive(:client_login)
        subject.execute
      end

      context "when username and description flags are supplied" do
        let(:username) { "my-username" }
        let(:description) { "my-description" }

        before { argv.push("--username").push(username).push("--description").push(description) }

        it "should include login and description to login" do
          expect(subject).to receive(:client_login).with(env, hash_including(login: username, description: description))
          subject.execute
        end
      end
    end
  end
end
