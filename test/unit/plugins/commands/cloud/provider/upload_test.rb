# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/cloud/provider/upload")

describe VagrantPlugins::CloudCommand::ProviderCommand::Command::Upload do
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
  let(:provider_file) { double("provider-file") }
  let(:provider_file_size) { 1 }

  describe "#upload_provider" do
    let(:argv) { [] }
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:upload_url) { double("upload-url") }
    let(:uploader) { double("uploader") }

    before do
      allow(I18n).to receive(:t)
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(subject).to receive(:with_provider).
        with(account: account, org: org_name, box: box_name, version: box_version, provider: box_version_provider).
        and_yield(provider)
      allow(provider).to receive(:upload).and_yield(upload_url)
      allow(uploader).to receive(:upload!)
      allow(Vagrant::UI::Prefixed).to receive(:new).with(ui, "cloud").and_return(ui)
      allow(Vagrant::Util::Uploader).to receive(:new).and_return(uploader)
      allow(File).to receive(:stat).with(provider_file).
        and_return(double("provider-stat", size: provider_file_size))
    end

    subject { described_class.new(argv, env) }

    it "should upload the provider file" do
      expect(provider).to receive(:upload)
      subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
    end

    it "should return zero on success" do
      r = subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
      expect(r).to eq(0)
    end

    it "should return non-zero on API error" do
      expect(provider).to receive(:upload).and_raise(VagrantCloud::Error)
      r = subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
      expect(r).not_to eq(0)
      expect(r).to be_a(Integer)
    end

    it "should return non-zero on upload error" do
      expect(provider).to receive(:upload).and_raise(Vagrant::Errors::UploaderError)
      r = subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
      expect(r).not_to eq(0)
      expect(r).to be_a(Integer)
    end

    it "should should upload via uploader" do
      expect(uploader).to receive(:upload!)
      subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
    end

    it "should not use direct upload by default" do
      expect(provider).to receive(:upload) do |**args|
        expect(args[:direct]).to be_falsey
      end
      subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
    end

    context "with direct option" do
      let(:options) { {direct: true} }

      it "should use direct upload" do
        expect(provider).to receive(:upload) do |**args|
          expect(args[:direct]).to be_truthy
        end
        subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
      end

      context "when file size is 5GB" do
        let(:provider_file_size) { 5368709120 }

        it "should use direct upload" do
          expect(provider).to receive(:upload) do |**args|
            expect(args[:direct]).to be_truthy
          end
          subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
        end
      end

      context "when file size is greater than 5GB" do
        let(:provider_file_size) { 5368709121 }

        it "should disable direct upload" do
          expect(provider).to receive(:upload) do |**args|
            expect(args[:direct]).to be_falsey
          end
          subject.upload_provider(org_name, box_name, box_version, box_version_provider, provider_file, access_token, options)
        end
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
      allow(subject).to receive(:upload_provider)
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

          it "shows help" do
            expect { subject.execute }.
              to raise_error(Vagrant::Errors::CLIInvalidUsage)
          end

          context "with file argument" do
            let(:file_arg) { "/dev/null/file" }

            before { argv << file_arg }

            it "should upload the provider file" do
              expect(subject).to receive(:upload_provider).
                with(org_name, box_name, version_arg, provider_arg, file_arg, any_args)
              subject.execute
            end

            it "should do direct upload by default" do
              expect(subject).to receive(:upload_provider).
                with(any_args, hash_including(direct: true))
              subject.execute
            end

            context "with --no-direct flag" do
              before { argv << "--no-direct" }

              it "should not perform direct upload" do
                expect(subject).to receive(:upload_provider).
                  with(any_args, hash_including(direct: false))
                subject.execute
              end
            end
          end
        end
      end
    end
  end
end
