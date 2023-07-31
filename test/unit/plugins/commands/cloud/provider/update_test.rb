# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/cloud/provider/update")

describe VagrantPlugins::CloudCommand::ProviderCommand::Command::Update do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:box_version) { "1.0.0" }
  let(:box_version_provider) { "my-provider" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box", versions: [version]) }
  let(:version) { double("version", version: box_version, provdiers: [provider]) }
  let(:provider) { double("provider", name: box_version_provider) }
  let(:provider_url) { nil }

  describe "#update_provider" do
    let(:argv) { [] }
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(subject).to receive(:with_provider).
        with(account: account, org: org_name, box: box_name, version: box_version, provider: box_version_provider).
        and_yield(provider)
      allow(provider).to receive(:save)
      allow(subject).to receive(:format_box_results)
    end

    subject { described_class.new(argv, env) }

    it "should update the provider" do
      expect(provider).to receive(:save)
      subject.update_provider(org_name, box_name, box_version, box_version_provider, provider_url, access_token, options)
    end

    it "should return 0 on success" do
      result = subject.update_provider(org_name, box_name, box_version, box_version_provider, provider_url, access_token, options)
      expect(result).to eq(0)
    end

    it "should return non-zero result on error" do
      expect(provider).to receive(:save).and_raise(VagrantCloud::Error)
      result = subject.update_provider(org_name, box_name, box_version, box_version_provider, provider_url, access_token, options)
      expect(result).not_to eq(0)
      expect(result).to be_a(Integer)
    end

    it "should not update the URL when unset" do
      expect(provider).not_to receive(:url=)
      subject.update_provider(org_name, box_name, box_version, box_version_provider, provider_url, access_token, options)
    end

    context "when URL is set" do
      let(:provider_url) { double("provider-url") }

      it "should update the URL" do
        expect(provider).to receive(:url=).with(provider_url)
        subject.update_provider(org_name, box_name, box_version, box_version_provider, provider_url, access_token, options)
      end
    end

    context "with options set" do
      let(:checksum) { double("checksum") }
      let(:checksum_type) { double("checksum_type") }
      let(:options) { {checksum: checksum, checksum_type: checksum_type} }

      it "should set checksum options before saving" do
        expect(provider).to receive(:checksum=).with(checksum)
        expect(provider).to receive(:checksum_type=).with(checksum_type)
        subject.update_provider(org_name, box_name, box_version, box_version_provider, provider_url, access_token, options)
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
      allow(subject).to receive(:update_provider)
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
            expect(subject).to receive(:update_provider).with(org_name, box_name, version_arg, provider_arg, any_args)
            subject.execute
          end

          it "should not provide URL value" do
            expect(subject).to receive(:update_provider).with(org_name, box_name, version_arg, provider_arg, nil, any_args)
            subject.execute
          end

          context "with URL argument" do
            let(:url_arg) { "provider-url" }

            before { argv << url_arg }

            it "should provide the URL value" do
              expect(subject).to receive(:update_provider).with(org_name, box_name, version_arg, provider_arg, url_arg, any_args)
              subject.execute
            end
          end

          context "with checksum and checksum type flags" do
            let(:checksum_arg) { "checksum" }
            let(:checksum_type_arg) { "checksum_type" }

            before { argv.push("--checksum").push(checksum_arg).push("--checksum-type").push(checksum_type_arg) }

            it "should include the checksum options" do
              expect(subject).to receive(:update_provider).
                with(org_name, box_name, version_arg, provider_arg, any_args, hash_including(checksum: checksum_arg, checksum_type: checksum_type_arg))
              subject.execute
            end
          end
        end
      end
    end
  end
end
