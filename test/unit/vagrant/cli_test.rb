# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../base"

require "vagrant/cli"
require "vagrant/util"

describe Vagrant::CLI do
  include_context "unit"
  include_context "command plugin helpers"

  let(:commands) { {} }
  let(:iso_env) { isolated_environment }
  let(:env)     { iso_env.create_vagrant_env }
  let(:checkpoint) { double("checkpoint") }

  before do
    allow(Vagrant.plugin("2").manager).to receive(:commands).and_return(commands)
    allow(Vagrant::Util::CheckpointClient).to receive(:instance).and_return(checkpoint)
    allow(checkpoint).to receive(:setup).and_return(checkpoint)
    allow(checkpoint).to receive(:check)
    allow(checkpoint).to receive(:display)
  end

  describe "#initialize" do
    it "should setup checkpoint" do
      expect(checkpoint).to receive(:check)
      described_class.new(["destroy"], env)
    end
  end

  describe "#execute" do
    let(:triggers) { double("triggers") }

    it "invokes help and exits with 1 if invalid command" do
      subject = described_class.new(["i-dont-exist"], env)
      expect(subject).to receive(:help).once
      expect(subject.execute).to eql(1)
    end

    it "invokes command and returns its exit status if the command is valid" do
      commands[:destroy] = [command_lambda("destroy", 42), {}]

      subject = described_class.new(["destroy"], env)
      expect(subject).not_to receive(:help)
      expect(subject.execute).to eql(42)
    end

    it "returns exit code 1 if interrupted" do
      commands[:destroy] = [command_lambda("destroy", 42, exception: Interrupt), {}]

      subject = described_class.new(["destroy"], env)
      expect(subject.execute).to eql(1)
    end

    it "displays any checkpoint information" do
      commands[:destroy] = [command_lambda("destroy", 42), {}]
      expect(checkpoint).to receive(:display)
      described_class.new(["destroy"], env).execute
    end

    it "fires triggers, if enabled" do
      allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).
        with("typed_triggers").and_return(true)
      allow(triggers).to receive(:fire)
      allow(triggers).to receive(:find).and_return([double("trigger-result")])

      commands[:destroy] = [command_lambda("destroy", 42), {}]

      allow(Vagrant::Plugin::V2::Trigger).to receive(:new).and_return(triggers)

      subject = described_class.new(["destroy"], env)

      expect(triggers).to receive(:fire).twice

      expect(subject).not_to receive(:help)
      expect(subject.execute).to eql(42)
    end

    it "does not fire triggers if disabled" do
      allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).
        with("typed_triggers").and_return(false)

      commands[:destroy] = [command_lambda("destroy", 42), {}]

      subject = described_class.new(["destroy"], env)

      expect(triggers).not_to receive(:fire)

      expect(subject).not_to receive(:help)
      expect(subject.execute).to eql(42)
    end
  end

  describe "#help" do
    subject { described_class.new([], env) }

    it "includes all primary subcommands" do
      commands[:foo] = [command_lambda("foo", 0), { primary: true }]
      commands[:bar] = [command_lambda("bar", 0), { primary: true }]
      commands[:baz] = [command_lambda("baz", 0), { primary: false }]

      expect(env.ui).to receive(:info).with(any_args) { |message, opts|
        expect(message).to include("foo")
        expect(message).to include("bar")
        expect(message.include?("baz")).to be(false)
      }

      subject.help
    end
  end
end
