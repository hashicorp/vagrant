# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/autocomplete/command/install")

describe VagrantPlugins::CommandAutocomplete::Command::Install do
  include_context "unit"

  let(:argv)     { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:homedir) { Dir.mktmpdir("homedir") }

  before {
    allow(Dir).to receive(:home) { homedir }
  }

  after {
    FileUtils.rm_rf(homedir)
  }

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
  end

  context "with no arguments" do
    it "returns without errors" do
      expect(subject.execute).to be(0)
    end
  end
end
