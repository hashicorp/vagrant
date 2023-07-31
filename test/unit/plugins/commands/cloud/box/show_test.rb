# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/box/show")

describe VagrantPlugins::CloudCommand::BoxCommand::Command::Show do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box") }

  describe "#show_box" do
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:argv) { [] }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(subject).to receive(:with_box).with(account: account, org: org_name, box: box_name).
        and_yield(box)
      allow(account).to receive(:organization).with(name: org_name).
        and_return(organization)
      allow(subject).to receive(:format_box_results)
    end

    subject { described_class.new(argv, env) }

    it "should return 0 on success" do
      expect(subject.show_box(org_name, box_name, access_token, options)).to eq(0)
    end

    it "should display the box results" do
      expect(subject).to receive(:format_box_results).with(box, env)
      subject.show_box(org_name, box_name, access_token, options)
    end

    it "should return non-zero on error" do
      expect(subject).to receive(:with_box).and_raise(VagrantCloud::Error)
      result = subject.show_box(org_name, box_name, access_token, options)
      expect(result).not_to eq(0)
      expect(result).to be_a(Integer)
    end

    context "with version defined" do
      let(:options) { {versions: [version]} }
      let(:box_version) { double("box_version", version: version) }
      let(:box_versions) { [box_version] }
      let(:version) { double("version") }

      before do
        allow(box).to receive(:versions).and_return(box_versions)
      end

      it "should print the version details" do
        expect(subject).to receive(:format_box_results).with(box_version, env)
        subject.show_box(org_name, box_name, access_token, options)
      end

      context "when version is not found" do
        let(:box_versions) { [] }

        it "should return non-zero" do
          result = subject.show_box(org_name, box_name, access_token, options)
          expect(result).not_to eq(0)
          expect(result).to be_a(Integer)
        end

        it "should not print any box information" do
          expect(subject).not_to receive(:format_box_results)
          subject.show_box(org_name, box_name, access_token, options)
        end
      end
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
      allow(subject).to receive(:show_box)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with box name argument" do
      let (:argv) { ["#{org_name}/#{box_name}"] }

      it "should show the box" do
        expect(subject).to receive(:show_box).with(org_name, box_name, any_args)
        subject.execute
      end

      it "should create the client login quietly" do
        expect(subject).to receive(:client_login).with(iso_env, hash_including(quiet: true))
        subject.execute
      end

      context "with auth flag" do
        before { argv.push("--auth") }

        it "should set quiet option to false when creating client" do
          expect(subject).to receive(:client_login).with(iso_env, hash_including(quiet: false))
          subject.execute
        end
      end

      context "with versions flag set" do
        let(:version_option) { "1.0.0" }

        before { argv.push("--versions").push(version_option) }

        it "should show box with version option set" do
          expect(subject).to receive(:show_box).
            with(org_name, box_name, access_token, hash_including(versions: [version_option]))
          subject.execute
        end
      end
    end
  end
end
