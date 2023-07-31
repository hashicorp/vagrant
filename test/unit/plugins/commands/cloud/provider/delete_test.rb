# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/cloud/provider/delete")

describe VagrantPlugins::CloudCommand::ProviderCommand::Command::Delete do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:box_version) { "1.0.0" }
  let(:box_version_provider) { "my-provider" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box", versions: [version]) }
  let(:version) { double("version", version: box_version, providers: [provider]) }
  let(:provider) { double("provider", name: box_version_provider) }

  describe "#delete_provider" do
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:argv) { [] }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(subject).to receive(:with_provider).
        with(account: account, org: org_name, box: box_name, version: box_version, provider: box_version_provider).
        and_yield(provider)
      allow(provider).to receive(:delete)
    end

    subject { described_class.new(argv, env) }

    it "should delete the provider" do
      expect(provider).to receive(:delete)
      subject.delete_provider(org_name, box_name, box_version, box_version_provider, access_token, options)
    end

    it "should return zero on success" do
      r = subject.delete_provider(org_name, box_name, box_version, box_version_provider, access_token, options)
      expect(r).to eq(0)
    end

    context "when error is encountered" do
      before do
        expect(provider).to receive(:delete).and_raise(VagrantCloud::Error)
      end

      it "should return non-zero" do
        r = subject.delete_provider(org_name, box_name, box_version, box_version_provider, access_token, options)
        expect(r).to be_a(Integer)
        expect(r).not_to eq(0)
      end
    end
  end

  describe "#execute" do
    let(:argv) { [] }
    let(:iso_env) do
      # We have to create a Vagrantfile so there is a root path
      env = isolated_environment
      env.vagrantfile("")
      env.create_vagrant_env
    end

    subject { described_class.new(argv, iso_env) }

    let(:action_runner) { double("action_runner") }
    let(:client) { double("client", token: access_token) }

    before do
      allow(iso_env).to receive(:action_runner).and_return(action_runner)
      allow(subject).to receive(:client_login).
        and_return(client)
      allow(iso_env.ui).to receive(:ask).
        and_return("y")
      allow(subject).to receive(:delete_provider)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with box name argument" do
      let(:argv) { ["#{org_name}/#{box_name}"] }

      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end

      context "with provider argument" do
        let(:provider_arg) { "my-provider" }

        before { argv << provider_arg }

        it "shows help" do
          expect { subject.execute }.
            to raise_error(Vagrant::Errors::CLIInvalidUsage)
        end

        context "with version argument" do
          let(:version_arg) { "1.0.0" }

          before { argv << version_arg }

          it "should delete the provider" do
            expect(subject).to receive(:delete_provider).
              with(org_name, box_name, version_arg, provider_arg, access_token, anything)
            subject.execute
          end

          it "should prompt for confirmation" do
            expect(iso_env.ui).to receive(:ask).and_return("y")
            subject.execute
          end

          context "with force flag" do
            before { argv << "--force" }

            it "should not prompt for confirmation" do
              expect(iso_env.ui).not_to receive(:ask)
              subject.execute
            end
          end
        end
      end
    end
  end
end
