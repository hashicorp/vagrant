# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/cloud/provider/create")

describe VagrantPlugins::CloudCommand::ProviderCommand::Command::Create do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:box_version) { "0.1.0" }
  let(:provider_name) { "my-provider" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box", versions: [version]) }
  let(:version) { double("version", version: box_version, providers: [provider]) }
  let(:provider) { double("provider", name: provider_name) }
  let(:provider_url) { double("provider_url") }

  describe "#create_provider" do
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:argv) { [] }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(subject).to receive(:with_version).with(account: account, org: org_name, box: box_name, version: box_version).
        and_yield(version)
      allow(account).to receive(:organization).with(name: org_name).
        and_return(organization)
      allow(version).to receive(:add_provider).and_return(provider)
      allow(provider).to receive(:save)
      allow(provider).to receive(:url=)
      allow(subject).to receive(:format_box_results)
    end

    subject { described_class.new(argv, env) }

    it "should add a new provider to the box version" do
      expect(version).to receive(:add_provider).with(provider_name)
      subject.create_provider(org_name, box_name, box_version, provider_name, provider_url, access_token, options)
    end

    it "should not set checksum or checksum_type when not provided" do
      expect(provider).not_to receive(:checksum=)
      expect(provider).not_to receive(:checksum_type=)
      subject.create_provider(org_name, box_name, box_version, provider_name, provider_url, access_token, options)
    end

    context "with checksum and checksum type options set" do
      let(:checksum) { double("checksum") }
      let(:checksum_type) { double("checksum_type") }
      let(:options) { {checksum: checksum, checksum_type: checksum_type} }

      it "should set the checksum and checksum type" do
        expect(provider).to receive(:checksum=).with(checksum)
        expect(provider).to receive(:checksum_type=).with(checksum_type)
        subject.create_provider(org_name, box_name, box_version, provider_name, provider_url, access_token, options)
      end
    end

    context "when URL is set" do
      it "should set the URL" do
        expect(provider).to receive(:url=).with(provider_url)
        subject.create_provider(org_name, box_name, box_version, provider_name, provider_url, access_token, options)
      end
    end

    context "when URL is not set" do
      let(:provider_url) { nil }

      it "should not set the URL" do
        expect(provider).not_to receive(:url=).with(provider_url)
        subject.create_provider(org_name, box_name, box_version, provider_name, provider_url, access_token, options)
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
      allow(subject).to receive(:create_provider)
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

          it "should create the provider" do
            expect(subject).to receive(:create_provider).with(org_name, box_name, version_arg, provider_arg, any_args)
            subject.execute
          end

          it "should not provide URL value" do
            expect(subject).to receive(:create_provider).with(org_name, box_name, version_arg, provider_arg, nil, any_args)
            subject.execute
          end

          context "with URL argument" do
            let(:url_arg) { "provider-url" }

            before { argv << url_arg }

            it "should provide the URL value" do
              expect(subject).to receive(:create_provider).with(org_name, box_name, version_arg, provider_arg, url_arg, any_args)
              subject.execute
            end
          end

          context "with checksum and checksum type flags" do
            let(:checksum_arg) { "checksum" }
            let(:checksum_type_arg) { "checksum_type" }

            before { argv.push("--checksum").push(checksum_arg).push("--checksum-type").push(checksum_type_arg) }

            it "should include the checksum options" do
              expect(subject).to receive(:create_provider).
                with(org_name, box_name, version_arg, provider_arg, any_args, hash_including(checksum: checksum_arg, checksum_type: checksum_type_arg))
              subject.execute
            end
          end
        end
      end
    end
  end
end
