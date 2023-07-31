# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../base", __FILE__)

describe "vagrant bin" do
  include_context "unit"

  let(:env) { isolated_environment }
  let(:ui) { double(:ui) }
  let(:argv) { [] }
  let(:exit_code) { 0 }

  let(:run_vagrant) {
    lambda {
      begin
        instance_eval(
          File.read(
            File.expand_path(
              "../../../../bin/vagrant", __FILE__)))
      rescue SystemExit => e
        e.status
      end
    }.call
  }

  before do
    allow(env).to receive(:ui).and_return(ui)
    allow(ARGV).to receive(:dup).and_return(argv)
    allow(env).to receive(:unload)
    allow(env).to receive(:cli).and_return(exit_code)
    allow(Kernel).to receive(:at_exit)
    allow(Kernel).to receive(:exit)
    allow(Vagrant::Environment).to receive(:new).and_return(env)
    allow(Vagrant).to receive(:in_installer?).and_return(true)
    allow(self).to receive(:require_relative)
  end

  after { expect(run_vagrant).to eq(exit_code) }

  it "should run the CLI and exit successfully" do
    expect(env).to receive(:cli).with(argv).and_return(exit_code)
    expect(run_vagrant).to eq(exit_code)
  end

  context "with flag" do
    describe "--version" do
      let(:argv) { ["--version"] }
      before { allow(self).to receive(:require_relative).with(/version/) }

      it "should output the current version" do
        expect($stdout).to receive(:puts).with(/#{Regexp.escape(Vagrant::VERSION.to_s)}/)
      end
    end

    describe "--timestamp" do
      let(:argv) { ["--timestamp"] }

      it "should enable timestamps on logs" do
        expect(ENV).to receive(:[]=).with("VAGRANT_LOG_TIMESTAMP", "1")
      end
    end

    describe "--debug-timestamp" do
      let(:argv) { ["--debug-timestamp"] }

      it "should enable debugging and log timestamps" do
        expect(ENV).to receive(:[]=).with("VAGRANT_LOG_TIMESTAMP", "1")
        expect(ENV).to receive(:[]=).with("VAGRANT_LOG", "debug")
      end
    end

    describe "--no-color" do
      let(:argv) { ["--no-color"] }

      it "should remove flag from argv" do
        expect(env).to receive(:cli).with([]).and_return(exit_code)
      end

      it "should pass a Basic UI instance" do
        expect(Vagrant::Environment).to receive(:new).
          with(hash_including(ui_class: Vagrant::UI::Basic))
      end
    end

    describe "--color" do
      let(:argv) { ["--color"] }

      it "should remove flag from argv" do
        expect(env).to receive(:cli).with([]).and_return(exit_code)
      end

      it "should pass a Colored UI instance" do
        expect(Vagrant::Environment).to receive(:new).
          with(hash_including(ui_class: Vagrant::UI::Colored))
      end
    end

    describe "--no-tty" do
      let(:argv) { ["--no-tty"] }

      it "should enable less verbose progress output" do
        expect(Vagrant::Environment).to receive(:new).
          with(hash_including(ui_class: Vagrant::UI::NonInteractive))
      end
    end
  end

  context "default CLI flags" do
    let(:argv) { ["--help"] }

    before do
      allow(env).to receive(:ui).and_return(ui)
      allow(ARGV).to receive(:dup).and_return(argv)
      allow(Kernel).to receive(:at_exit)
      allow(Kernel).to receive(:exit)
      allow(Vagrant::Environment).to receive(:new).and_call_original

      # Include this to intercept checkpoint instance setup
      # since it is a singleton
      allow(Vagrant::Util::CheckpointClient).
        to receive_message_chain(:instance, :setup, :check)
    end

    it "should include default CLI flags in command help output" do
      expect($stdout).to receive(:puts).with(/--debug/)
    end
  end

  context "when not in installer" do
    let(:warning) { "INSTALLER WARNING" }

    before do
      expect(Vagrant).to receive(:in_installer?).and_return(false)
      allow(I18n).to receive(:t).with(/not_in_installer/).and_return(warning)
    end

    context "when vagrant is not very quiet" do
      before { expect(Vagrant).to receive(:very_quiet?).and_return(false) }

      it "should output a warning" do
        expect(env.ui).to receive(:warn).with(/#{warning}/, any_args)
      end
    end

    context "when vagrant is very quiet" do
      before { expect(Vagrant).to receive(:very_quiet?).and_return(true) }

      it "should not output a warning" do
        expect(env.ui).not_to receive(:warn).with(/#{warning}/, any_args)
      end
    end
  end

  context "plugin commands" do
    let(:argv) { ["plugin"] }

    before do
      allow(ENV).to receive(:[]=)
      allow(ENV).to receive(:[])
    end

    it "should unset vagrantfile" do
      expect(Vagrant::Environment).to receive(:new).
        with(hash_including(vagrantfile_name: "")).and_return(env)
    end

    it "should set the no plugins environment variable" do
      expect(ENV).to receive(:[]=).with("VAGRANT_NO_PLUGINS", "1")
    end

    it "should set the disable plugin init environment variable" do
      expect(ENV).to receive(:[]=).with("VAGRANT_DISABLE_PLUGIN_INIT", "1")
    end

    context "list" do
      let(:argv) { ["plugin", "list"] }

      it "should not set the disable plugin init environment variable" do
        expect(ENV).not_to receive(:[]=).with("VAGRANT_DISABLE_PLUGIN_INIT", "1")
      end
    end

    context "--local" do
      let(:argv) { ["plugin", "install", "--local"] }

      it "should not unset vagrantfile" do
        expect(Vagrant::Environment).to receive(:new).
          with(hash_excluding(vagrantfile_name: "")).and_return(env)
      end
    end

    context "with VAGRANT_LOCAL_PLUGINS_LOAD enabled" do
      before { expect(ENV).to receive(:[]).with("VAGRANT_LOCAL_PLUGINS_LOAD").and_return("1") }

      it "should not unset vagrantfile" do
        expect(Vagrant::Environment).to receive(:new).
          with(hash_excluding(vagrantfile_name: "")).and_return(env)
      end
    end
  end
end
