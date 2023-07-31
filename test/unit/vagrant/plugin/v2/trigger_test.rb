# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/kernel_v2/config/trigger")

describe Vagrant::Plugin::V2::Trigger do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    isolated_environment.tap do |env|
      env.vagrantfile("")
    end
  end
  let(:iso_vagrant_env) { iso_env.create_vagrant_env }
  let(:state) { double("state", id: :running) }
  let(:machine) do
    iso_vagrant_env.machine(iso_vagrant_env.machine_names[0], :dummy).tap do |m|
      allow(m).to receive(:state).and_return(state)
    end
  end
  let(:ui) { Vagrant::UI::Silent.new }
  let(:env) { {
    machine: machine,
    ui: ui,
  } }

  let(:triggers) {
    @triggers ||= VagrantPlugins::Kernel_V2::TriggerConfig.new.tap do |triggers|
      triggers.before(:up, hash_block)
      triggers.before(:destroy, hash_block)
      triggers.before(:halt, hash_block_two)
      triggers.after(:up, hash_block)
      triggers.after(:destroy, hash_block)
      triggers.finalize!
    end
  }
  let(:hash_block) { {info: "hi", run: {inline: "echo 'hi'"}} }
  let(:hash_block_two) { {warn: "WARNING!!", run_remote: {inline: "echo 'hi'"}} }

  let(:subject) { described_class.new(env, triggers, machine, ui) }

  describe "#fire" do
    it "raises an error if an improper stage is given" do
      expect{ subject.fire(:up, :not_real, "guest", :action) }.
       to raise_error(Vagrant::Errors::TriggersNoStageGiven)
    end

    it "does not fire triggers if community plugin is detected" do
      allow(subject).to receive(:community_plugin_detected?).and_return(true)

      expect(subject).not_to receive(:execute)
      subject.fire(:up, :before, "guest", :action)
    end

    it "does fire triggers if community plugin is not detected" do
      allow(subject).to receive(:community_plugin_detected?).and_return(false)

      expect(subject).to receive(:execute)
      subject.fire(:up, :before, "guest", :action)
    end
  end

  describe "#find" do
    it "raises an error if an improper stage is given" do
      expect { subject.find(:up, :not_real, "guest", :action) }.
        to raise_error(Vagrant::Errors::TriggersNoStageGiven)
    end

    it "returns empty array when no triggers are found" do
      expect(subject.find(:halt, :after, "guest", :action)).to be_empty
    end

    it "returns items in array when triggers are found" do
      expect(subject.find(:halt, :before, "guest", :action)).not_to be_empty
    end

    it "returns the execpted number of items in the array when triggers are found" do
      expect(subject.find(:halt, :before, "guest", :action).count).to eq(1)
    end

    it "filters all found triggers" do
      expect(subject).to receive(:filter_triggers)
      subject.find(:halt, :before, "guest", :action)
    end

    it "should not attempt to match hook name with non-hook type" do
      expect(subject).not_to receive(:matched_hook?)
      subject.find(:halt, :before, "guest", :action)
    end

    context "with :all special value" do
      let(:triggers) { VagrantPlugins::Kernel_V2::TriggerConfig.new }
      let(:ignores) { [] }

      before do
        triggers.before(:all, hash_block.merge(ignore: ignores))
        triggers.after(:all, hash_block.merge(ignore: ignores))
        triggers.finalize!
      end

      [:destroy, :halt, :provision, :reload, :resume, :suspend, :up].each do |supported_action|
        it "should locate trigger when before #{supported_action} action is requested" do
          expect(subject.find(supported_action, :before, "guest", :action, all: true)).not_to be_empty
        end

        it "should locate trigger when after #{supported_action} action is requested" do
          expect(subject.find(supported_action, :after, "guest", :action, all: true)).not_to be_empty
        end
      end

      context "with ignores" do
        let(:ignores) { [:halt, :up] }

        it "should not locate trigger when before command is ignored" do
          expect(subject.find(:up, :before, "guest", :action, all: true)).to be_empty
        end

        it "should not locate trigger when after command is ignored" do
          expect(subject.find(:halt, :after, "guest", :action, all: true)).to be_empty
        end

        it "should locate trigger when before command is not ignored" do
          expect(subject.find(:provision, :before, "guest", :action, all: true)).not_to be_empty
        end

        it "should locate trigger when after command is not ignored" do
          expect(subject.find(:provision, :after, "guest", :action, all: true)).not_to be_empty
        end
      end
    end

    context "with hook type" do
      before do
        triggers.before(:environment_load, hash_block.merge(type: :hook))
        triggers.before(Vagrant::Action::Builtin::SyncedFolders, hash_block.merge(type: :hook))
        triggers.finalize!
      end

      it "returns empty array when no triggers are found" do
        expect(subject.find(:environment_unload, :before, "guest", :hook)).to be_empty
      end

      it "returns items in array when triggers are found" do
        expect(subject.find(:environment_load, :before, "guest", :hook).size).to eq(1)
      end

      it "should locate hook trigger using class constant" do
        expect(subject.find(Vagrant::Action::Builtin::SyncedFolders, :before, "guest", :hook)).
          not_to be_empty
      end

      it "should locate hook trigger using string" do
        expect(subject.find("environment_load", :before, "guest", :hook)).not_to be_empty
      end

      it "should locate hook trigger using full converted name" do
        expect(subject.find(:vagrant_action_builtin_synced_folders, :before, "guest", :hook)).
          not_to be_empty
      end

      it "should locate hook trigger using partial suffix converted name" do
        expect(subject.find(:builtin_synced_folders, :before, "guest", :hook)).
          not_to be_empty
      end

      it "should not locate hook trigger using partial prefix converted name" do
        expect(subject.find(:vagrant_action, :before, "guest", :hook)).
          to be_empty
      end
    end
  end

  describe "#filter_triggers" do
    it "returns all triggers if no constraints" do
      before_triggers = triggers.before_triggers
      filtered_triggers = subject.send(:filter_triggers, before_triggers, "guest", :action)
      expect(filtered_triggers).to eq(before_triggers)
    end

    it "filters a trigger if it doesn't match guest_name" do
      trigger_config = {info: "no", only_on: "notrealguest"}
      triggers.after(:up, trigger_config)
      triggers.finalize!

      after_triggers = triggers.after_triggers
      expect(after_triggers.size).to eq(3)
      subject.send(:filter_triggers, after_triggers, :ubuntu, :action)
      expect(after_triggers.size).to eq(2)
    end

    it "keeps a trigger that has a restraint that matches guest name" do
      trigger_config = {info: "no", only_on: /guest/}
      triggers.after(:up, trigger_config)
      triggers.finalize!

      after_triggers = triggers.after_triggers
      expect(after_triggers.size).to eq(3)
      subject.send(:filter_triggers, after_triggers, "ubuntu-guest", :action)
      expect(after_triggers.size).to eq(3)
    end

    it "keeps a trigger that has multiple restraints that matches guest name" do
      trigger_config = {info: "no", only_on: ["debian", /guest/]}
      triggers.after(:up, trigger_config)
      triggers.finalize!

      after_triggers = triggers.after_triggers
      expect(after_triggers.size).to eq(3)
      subject.send(:filter_triggers, after_triggers, "ubuntu-guest", :action)
      expect(after_triggers.size).to eq(3)
    end
  end

  describe "#execute" do
    it "calls the corresponding trigger methods if options set" do
      expect(subject).to receive(:info).twice
      expect(subject).to receive(:warn).once
      expect(subject).to receive(:run).twice
      expect(subject).to receive(:run_remote).once
      subject.send(:execute, triggers.before_triggers)
    end
  end

  describe "#info" do
    let(:message) { "Printing some info" }

    it "prints messages at INFO" do
      expect(ui).to receive(:info).with(message).and_call_original

      subject.send(:info, message)
    end
  end

  describe "#warn" do
    let(:message) { "Printing some warnings" }

    it "prints messages at WARN" do
      expect(ui).to receive(:warn).with(message).and_call_original

      subject.send(:warn, message)
    end
  end

  describe "#run" do
    let(:trigger_run) { VagrantPlugins::Kernel_V2::TriggerConfig.new }
    let(:shell_block) { {info: "hi", run: {inline: "echo 'hi'", env: {"KEY"=>"VALUE"}}} }
    let(:shell_block_exit_codes) {
      {info: "hi", run: {inline: "echo 'hi'", env: {"KEY"=>"VALUE"}},
       exit_codes: [0,50]} }
    let(:path_block) { {warn: "bye",
                         run: {path: "path/to the/script.sh", args: "HELLO", env: {"KEY"=>"VALUE"}},
                         on_error: :continue} }

    let(:path_block_ps1) { {warn: "bye",
                         run: {path: "script.ps1", args: ["HELLO", "THERE"], env: {"KEY"=>"VALUE"}},
                         on_error: :continue} }

    let(:exit_code) { 0 }
    let(:options) { {:notify=>[:stdout, :stderr]} }

    let(:subprocess_result) do
      double("subprocess_result").tap do |result|
        allow(result).to receive(:exit_code).and_return(exit_code)
        allow(result).to receive(:stderr).and_return("")
      end
    end

    let(:subprocess_result_failure) do
      double("subprocess_result_failure").tap do |result|
        allow(result).to receive(:exit_code).and_return(1)
        allow(result).to receive(:stderr).and_return("")
      end
    end

    let(:subprocess_result_custom) do
      double("subprocess_result_custom").tap do |result|
        allow(result).to receive(:exit_code).and_return(50)
        allow(result).to receive(:stderr).and_return("")
      end
    end

    before do
      trigger_run.after(:up, shell_block)
      trigger_run.after(:up, shell_block_exit_codes)
      trigger_run.before(:destroy, path_block)
      trigger_run.before(:destroy, path_block_ps1)
      trigger_run.finalize!
    end

    it "executes an inline script with powershell if windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      allow(Vagrant::Util::PowerShell).to receive(:execute_inline).
        and_yield(:stderr, "some output").
        and_return(subprocess_result)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::PowerShell).to receive(:execute_inline).
        with("echo 'hi'", options)
      subject.send(:run, shell_config, on_error, exit_codes)
    end

    it "executes a path script with powershell if windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      allow(Vagrant::Util::PowerShell).to receive(:execute).
        and_yield(:stdout, "more output").
        and_return(subprocess_result)
      allow(env).to receive(:root_path).and_return("/vagrant/home")

      trigger = trigger_run.before_triggers[1]
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::PowerShell).to receive(:execute).
        with("/vagrant/home/script.ps1", "HELLO", "THERE", options)
      subject.send(:run, shell_config, on_error, exit_codes)
    end

    it "executes an inline script" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(subprocess_result)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("echo", "hi", options)
      subject.send(:run, shell_config, on_error, exit_codes)
    end

    it "executes a path script" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(subprocess_result)
      allow(env).to receive(:root_path).and_return("/vagrant/home")
      allow(FileUtils).to receive(:chmod).and_return(true)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("/vagrant/home/path/to the/script.sh", "HELLO", options)
      subject.send(:run, shell_config, on_error, exit_codes)
    end

    it "continues on error" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_raise("Fail!")
      allow(env).to receive(:root_path).and_return("/vagrant/home")
      allow(FileUtils).to receive(:chmod).and_return(true)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("/vagrant/home/path/to the/script.sh", "HELLO", options)
      subject.send(:run, shell_config, on_error, exit_codes)
    end

    it "halts on error" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_raise("Fail!")

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("echo", "hi", options)
      expect { subject.send(:run, shell_config, on_error, exit_codes) }.to raise_error("Fail!")
    end

    it "allows for acceptable exit codes" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(subprocess_result_custom)

      trigger = trigger_run.after_triggers[1]
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("echo", "hi", options)
      subject.send(:run, shell_config, on_error, exit_codes)
    end

    it "exits if given a bad exit code" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(subprocess_result_custom)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("echo", "hi", options)
      expect { subject.send(:run, shell_config, on_error, exit_codes) }.to raise_error(Vagrant::Errors::TriggersBadExitCodes)
    end
  end

  describe "#run_remote" do
    let (:trigger_run) { VagrantPlugins::Kernel_V2::TriggerConfig.new }
    let (:shell_block) { {info: "hi", run_remote: {inline: "echo 'hi'", env: {"KEY"=>"VALUE"}}} }
    let (:path_block) { {warn: "bye",
                         run_remote: {path: "script.sh", env: {"KEY"=>"VALUE"}},
                         on_error: :continue} }
    let(:provision) { double("provision") }

    before do
      trigger_run.after(:up, shell_block)
      trigger_run.before(:destroy, path_block)
      trigger_run.finalize!
    end

    context "with no machine existing" do
      let(:machine) { nil }

      it "raises an error and halts if guest does not exist" do
        trigger = trigger_run.after_triggers.first
        shell_config = trigger.run_remote
        on_error = trigger.on_error
        exit_codes = trigger.exit_codes

        expect { subject.send(:run_remote, shell_config, on_error, exit_codes) }.
          to raise_error(Vagrant::Errors::TriggersGuestNotExist)
      end

      it "continues on if guest does not exist but is configured to continue on error" do
        trigger = trigger_run.before_triggers.first
        shell_config = trigger.run_remote
        on_error = trigger.on_error
        exit_codes = trigger.exit_codes

        subject.send(:run_remote, shell_config, on_error, exit_codes)
      end
    end

    it "raises an error and halts if guest is not running" do
      allow(machine.state).to receive(:id).and_return(:not_running)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect { subject.send(:run_remote, shell_config, on_error, exit_codes) }.
        to raise_error(Vagrant::Errors::TriggersGuestNotRunning)
    end

    it "continues on if guest is not running but is configured to continue on error" do
      allow(machine.state).to receive(:id).and_return(:not_running)

      allow(env).to receive(:root_path).and_return("/vagrant/home")
      allow(FileUtils).to receive(:chmod).and_return(true)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      subject.send(:run_remote, shell_config, on_error, exit_codes)
    end

    it "calls the provision function on the shell provisioner" do
      allow(machine.state).to receive(:id).and_return(:running)
      allow(provision).to receive(:provision).and_return("Provision!")
      allow(VagrantPlugins::Shell::Provisioner).to receive(:new).
        and_return(provision)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      subject.send(:run_remote, shell_config, on_error, exit_codes)
    end

    it "continues on if provision fails" do
      allow(machine.state).to receive(:id).and_return(:running)
      allow(provision).to receive(:provision).and_raise("Nope!")
      allow(VagrantPlugins::Shell::Provisioner).to receive(:new).
        and_return(provision)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      subject.send(:run_remote, shell_config, on_error, exit_codes)
    end

    it "fails if it encounters an error" do
      allow(machine.state).to receive(:id).and_return(:running)
      allow(provision).to receive(:provision).and_raise("Nope!")
      allow(VagrantPlugins::Shell::Provisioner).to receive(:new).
        and_return(provision)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error
      exit_codes = trigger.exit_codes

      expect { subject.send(:run_remote, shell_config, on_error, exit_codes) }.
        to raise_error("Nope!")
    end
  end

  describe "#trigger_abort" do
    it "system exits when called" do
      allow(Process).to receive(:exit!).and_return(true)

      expect(Process).to receive(:exit!).with(3)
      subject.send(:trigger_abort, 3)
    end

    context "when running in parallel" do
      let(:thread) {
        @t ||= Thread.new do
          Thread.current[:batch_parallel_action] = true
          Thread.stop
          subject.send(:trigger_abort, exit_code)
        end
      }
      let(:exit_code) { 22 }

      before do
        expect(Process).not_to receive(:exit!)
        sleep(0.1) until thread.stop?
      end

      after { @t = nil }

      it "should terminate the thread" do
        expect(thread).to receive(:terminate).and_call_original
        thread.wakeup
        thread.join(1) while thread.alive?
      end

      it "should set the exit code into the thread data" do
        expect(thread).to receive(:terminate).and_call_original
        thread.wakeup
        thread.join(1) while thread.alive?
        expect(thread[:exit_code]).to eq(exit_code)
      end
    end
  end

  describe "#ruby" do
    let(:trigger_run) { VagrantPlugins::Kernel_V2::TriggerConfig.new }
    let(:block) { proc{var = 1+1} }
    let(:ruby_trigger) { {info: "hi", ruby: block} }

    before do
      trigger_run.after(:up, ruby_trigger)
      trigger_run.finalize!
    end

    it "executes a ruby block" do
      expect(block).to receive(:call)
      subject.send(:execute_ruby, block)
    end
  end

  describe "#nameify" do
    it "should return empty string when object" do
      expect(subject.send(:nameify, "")).to eq("")
    end

    it "should return name of class" do
      expect(subject.send(:nameify, String)).to eq("String")
    end

    it "should return empty string when class has no name" do
      expect(subject.send(:nameify, Class.new)).to eq("")
    end
  end
end
