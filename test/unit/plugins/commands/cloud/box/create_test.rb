# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/box/create")

describe VagrantPlugins::CloudCommand::BoxCommand::Command::Create do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box") }

  describe "#create_box" do
    let(:options) { {} }
    let(:env) { double("env", ui: ui) }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:argv) { [] }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(VagrantCloud::Account).to receive(:new).
        with(custom_server: anything, access_token: access_token).
        and_return(account)
      allow(account).to receive(:organization).with(name: org_name).
        and_return(organization)
      allow(subject).to receive(:format_box_results).with(box, env)
      allow(organization).to receive(:add_box).and_return(box)
      allow(box).to receive(:save)
    end

    subject { described_class.new(argv, env) }

    it "should add a new box to the organization" do
      expect(organization).to receive(:add_box).with(box_name).
        and_return(box)
      subject.create_box(org_name, box_name, access_token, options)
    end

    it "should save the new box" do
      expect(box).to receive(:save)
      subject.create_box(org_name, box_name, access_token, options)
    end

    it "should return a zero value on success" do
      expect(subject.create_box(org_name, box_name, access_token, options)).
        to eq(0)
    end

    it "should return a non-zero value on error" do
      expect(box).to receive(:save).and_raise(VagrantCloud::Error)
      result = subject.create_box(org_name, box_name, access_token, options)
      expect(result).not_to eq(0)
      expect(result).to be_a(Integer)
    end

    context "with option set" do
      let(:options) { {short: short, description: description, private: priv} }
      let(:short) { double("short") }
      let(:description) { double("description") }
      let(:priv) { double("private") }

      it "should set info into box" do
        expect(box).to receive(:short_description=).with(short)
        expect(box).to receive(:description=).with(description)
        expect(box).to receive(:private=).with(priv)
        subject.create_box(org_name, box_name, access_token, options)
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
    let(:box) { double("box") }

    before do
      allow(iso_env).to receive(:action_runner).and_return(action_runner)
      allow(subject).to receive(:client_login).and_return(client)
      allow(subject).to receive(:format_box_results)
      allow(subject).to receive(:create_box)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with box name argument" do
      let(:argv) { ["#{org_name}/#{box_name}"] }

      it "should create the box" do
        expect(subject).to receive(:create_box).with(org_name, box_name, any_args)
        subject.execute
      end

      context "when description flag is provided" do
        let(:description) { "my-description" }

        before { argv.push("--description").push(description) }

        it "should create box with given description" do
          expect(subject).to receive(:create_box).
            with(org_name, box_name, access_token, hash_including(description: description))
          subject.execute
        end
      end

      context "when short flag is provided" do
        let(:description) { "my-description" }

        before { argv.push("--short").push(description) }

        it "should create box with given short description" do
          expect(subject).to receive(:create_box).
            with(org_name, box_name, access_token, hash_including(short: description))
          subject.execute
        end
      end

      context "when private flag is provided" do
        before { argv.push("--private") }

        it "should create box as private" do
          expect(subject).to receive(:create_box).
            with(org_name, box_name, access_token, hash_including(private: true))
          subject.execute
        end
      end
    end
  end
end
