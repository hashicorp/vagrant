# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/cloud/box/update")

describe VagrantPlugins::CloudCommand::BoxCommand::Command::Update do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box") }

  describe "#update_box" do
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
      allow(box).to receive(:save)
    end

    subject { described_class.new(argv, env) }

    it "should save the box" do
      expect(box).to receive(:save)
      subject.update_box(org_name, box_name, access_token, options)
    end

    it "should return 0 on success" do
      result = subject.update_box(org_name, box_name, access_token, options)
      expect(result).to eq(0)
    end

    it "should return non-zero on error" do
      expect(box).to receive(:save).and_raise(VagrantCloud::Error)
      result = subject.update_box(org_name, box_name, access_token, options)
      expect(result).not_to eq(0)
      expect(result).to be_a(Integer)
    end

    it "should display the box information" do
      expect(subject).to receive(:format_box_results).with(box, env)
      subject.update_box(org_name, box_name, access_token, options)
    end

    context "with options set" do
      let(:options) { {short: short, description: description, private: priv} }
      let(:short) { double("short") }
      let(:description) { double("description") }
      let(:priv) { double("private") }

      it "should set box info" do
        expect(box).to receive(:short_description=).with(short)
        expect(box).to receive(:description=).with(description)
        expect(box).to receive(:private=).with(priv)
        subject.update_box(org_name, box_name, access_token, options)
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
      allow(subject).to receive(:client_login).and_return(client)
      allow(subject).to receive(:update_box)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with box name argument" do
      let(:argv) { ["#{org_name}/#{box_name}"] }

      it "should show help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end

      context "with description flag set" do
        let(:description) { "my-description" }

        before { argv.push("--description").push(description) }

        it "should update box with description" do
          expect(subject).to receive(:update_box).
            with(org_name, box_name, access_token, hash_including(description: description))
          subject.execute
        end
      end

      context "with short flag set" do
        let(:description) { "my-description" }

        before { argv.push("--short-description").push(description) }

        it "should update box with short description" do
          expect(subject).to receive(:update_box).
            with(org_name, box_name, access_token, hash_including(short: description))
          subject.execute
        end
      end

      context "with private flag set" do
        before { argv.push("--private") }

        it "should update box with private" do
          expect(subject).to receive(:update_box).
            with(org_name, box_name, access_token, hash_including(private: true))
          subject.execute
        end
      end
    end
  end
end
