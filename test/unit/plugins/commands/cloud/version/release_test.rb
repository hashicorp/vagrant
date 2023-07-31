# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/cloud/version/release")

describe VagrantPlugins::CloudCommand::VersionCommand::Command::Release do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:box_version) { double("box_version") }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box", versions: [version]) }
  let(:version) { double("version", version: box_version) }

  describe "#release_version" do
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:argv) { [] }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(subject).to receive(:with_version).
        with(account: account, org: org_name, box: box_name, version: box_version).
        and_yield(version)
      allow(version).to receive(:release)
    end

    subject { described_class.new(argv, env) }

    it "should release the version" do
      expect(version).to receive(:release)
      subject.release_version(org_name, box_name, box_version, access_token, options)
    end

    it "should return 0 on success" do
      result = subject.release_version(org_name, box_name, box_version, access_token, options)
      expect(result).to eq(0)
    end

    it "should return a non-zero on error" do
      expect(version).to receive(:release).and_raise(VagrantCloud::Error)
      result = subject.release_version(org_name, box_name, box_version, access_token, options)
      expect(result).not_to eq(0)
      expect(result).to be_a(Integer)
    end
  end

  describe "#execute" do
    let(:argv)     { [] }
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
      allow(subject).to receive(:release_version)
      allow(iso_env.ui).to receive(:ask).and_return("y")
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

      context "with version argument" do
        let(:version_arg) { "1.0.0" }

        before { argv << version_arg }

        it "should release the version" do
          expect(subject).to receive(:release_version).
            with(org_name, box_name, version_arg, access_token, anything)
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
