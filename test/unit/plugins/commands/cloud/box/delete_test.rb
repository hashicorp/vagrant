# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/box/delete")

describe VagrantPlugins::CloudCommand::BoxCommand::Command::Delete do
  include_context "unit"

  let(:access_token) { double("token") }
  let(:org_name) { "my-org" }
  let(:box_name) { "my-box" }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box") }

  describe "#delete_box" do
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
      allow(box).to receive(:delete)
    end

    subject { described_class.new(argv, env) }

    it "should return 0 on success" do
      expect(subject.delete_box(org_name, box_name, access_token)).to eq(0)
    end

    it "should delete the box" do
      expect(box).to receive(:delete)
      subject.delete_box(org_name, box_name, access_token)
    end

    it "should return non-zero on error" do
      expect(box).to receive(:delete).and_raise(VagrantCloud::Error)
      result = subject.delete_box(org_name, box_name, access_token)
      expect(result).not_to eq(0)
      expect(result).to be_a(Integer)
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
    let(:box) { double("box") }

    before do
      allow(iso_env).to receive(:action_runner).and_return(action_runner)
      allow(subject).to receive(:client_login).
        and_return(client)
      allow(iso_env.ui).to receive(:ask).
        and_return("y")
      allow(subject).to receive(:delete_box)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with box name argument" do
      let (:argv) { ["#{org_name}/#{box_name}"] }

      it "should delete the box" do
        expect(subject).to receive(:delete_box).
          with(org_name, box_name, access_token)
        subject.execute
      end

      it "should prompt for confirmation" do
        expect(iso_env.ui).to receive(:ask).and_return("y")
        subject.execute
      end

      context "with force flag" do
        before { argv.push("--force") }

        it "should not prompt for confirmation" do
          expect(iso_env.ui).not_to receive(:ask)
          subject.execute
        end
      end
    end
  end
end
