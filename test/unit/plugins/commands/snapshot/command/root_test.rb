# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/snapshot/command/root")

describe VagrantPlugins::CommandSnapshot::Command::Root do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:argv) { [] }

  subject { described_class.new(argv, iso_env) }

  describe "execute" do
    context "--help" do
      let(:argv)     { ["--help"] }
      it "shows help" do
        expect(iso_env.ui).
          to receive(:info).with(/Usage: vagrant snapshot <subcommand>/, anything)
        expect(subject.execute).to eq(0)
      end
    end

    context "with no subcommand" do
      let(:argv)     { [] }
      it "shows help and fails" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with invalid subcommand" do
      let(:argv)     { ["invalid"] }
      it "shows help and fails" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end
  end
end
