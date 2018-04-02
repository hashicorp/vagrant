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
  let(:env) { {
    machine: machine,
    ui: Vagrant::UI::Silent.new,
  } }

  let(:triggers) { VagrantPlugins::Kernel_V2::TriggerConfig.new }
  let(:hash_block) { {info: "hi", run: {inline: "echo 'hi'"}} }
  let(:hash_block_two) { {warn: "WARNING!!", run_remote: {inline: "echo 'hi'"}} }

  before do
    triggers.before(:up, hash_block)
    triggers.before(:destroy, hash_block)
    triggers.before(:halt, hash_block_two)
    triggers.after(:up, hash_block)
    triggers.after(:destroy, hash_block)
    triggers.finalize!
  end


  let(:subject) { described_class.new(env, triggers, machine) }

  context "#fire_triggers" do
    it "raises an error if an inproper stage is given" do
      expect{ subject.fire_triggers(:up, :not_real, "guest") }.
       to raise_error(Vagrant::Errors::TriggersNoStageGiven)
    end
  end

  context "#filter_triggers" do
    it "returns all triggers if no constraints" do
      before_triggers = triggers.before_triggers
      filtered_triggers = subject.send(:filter_triggers, before_triggers, "guest")
      expect(filtered_triggers).to eq(before_triggers)
    end

    it "filters a trigger if it doesn't match guest_name" do
      trigger_config = {info: "no", only_on: "notrealguest"}
      triggers.after(:up, trigger_config)
      triggers.finalize!

      after_triggers = triggers.after_triggers
      expect(after_triggers.size).to eq(3)
      subject.send(:filter_triggers, after_triggers, "ubuntu")
      expect(after_triggers.size).to eq(2)
    end

    it "keeps a trigger that has a restraint that matches guest name" do
      trigger_config = {info: "no", only_on: /guest/}
      triggers.after(:up, trigger_config)
      triggers.finalize!

      after_triggers = triggers.after_triggers
      expect(after_triggers.size).to eq(3)
      subject.send(:filter_triggers, after_triggers, "ubuntu-guest")
      expect(after_triggers.size).to eq(3)
    end

    it "keeps a trigger that has multiple restraints that matches guest name" do
      trigger_config = {info: "no", only_on: ["debian", /guest/]}
      triggers.after(:up, trigger_config)
      triggers.finalize!

      after_triggers = triggers.after_triggers
      expect(after_triggers.size).to eq(3)
      subject.send(:filter_triggers, after_triggers, "ubuntu-guest")
      expect(after_triggers.size).to eq(3)
    end
  end

  context "#fire" do
    it "calls the corresponding trigger methods if options set" do
      expect(subject).to receive(:info).twice
      expect(subject).to receive(:warn).once
      expect(subject).to receive(:run).twice
      expect(subject).to receive(:run_remote).once
      subject.send(:fire, triggers.before_triggers, "guest")
    end
  end

  context "#info" do
    let(:message) { "Printing some info" }

    it "prints messages at INFO" do
      output = ""
      allow(machine.ui).to receive(:info) do |data|
        output << data
      end

      subject.send(:info, message)
      expect(output).to include(message)
    end
  end

  context "#warn" do
    let(:message) { "Printing some warnings" }

    it "prints messages at WARN" do
      output = ""
      allow(machine.ui).to receive(:warn) do |data|
        output << data
      end

      subject.send(:warn, message)
      expect(output).to include(message)
    end
  end

  context "#run" do
    let(:trigger_run) { VagrantPlugins::Kernel_V2::TriggerConfig.new }
    let(:shell_block) { {info: "hi", run: {inline: "echo 'hi'", env: {"KEY"=>"VALUE"}}} }
    let(:path_block) { {warn: "bye",
                         run: {path: "script.sh", env: {"KEY"=>"VALUE"}},
                         on_error: :continue} }

    let(:exit_code) { 0 }
    let(:options) { {:notify=>[:stdout, :stderr]} }

    let(:subprocess_result) do
      double("subprocess_result").tap do |result|
        allow(result).to receive(:exit_code).and_return(exit_code)
        allow(result).to receive(:stderr).and_return("")
      end
    end

    before do
      trigger_run.after(:up, shell_block)
      trigger_run.before(:destroy, path_block)
      trigger_run.finalize!
    end

    it "executes an inline script" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(subprocess_result)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("echo", "hi", options)
      subject.send(:run, shell_config, on_error)
    end

    it "executes an path script" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_return(subprocess_result)
      allow(env).to receive(:root_path).and_return("/vagrant/home")
      allow(FileUtils).to receive(:chmod).and_return(true)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("/vagrant/home/script.sh", options)
      subject.send(:run, shell_config, on_error)
    end

    it "continues on error" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_raise("Fail!")
      allow(env).to receive(:root_path).and_return("/vagrant/home")
      allow(FileUtils).to receive(:chmod).and_return(true)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("/vagrant/home/script.sh", options)
      subject.send(:run, shell_config, on_error)
    end

    it "halts on error" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        and_raise("Fail!")

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run
      on_error = trigger.on_error

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("echo", "hi", options)
      expect { subject.send(:run, shell_config, on_error) }.to raise_error("Fail!")
    end
  end

  context "#run_remote" do
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

    it "raises an error and halts if guest is not running" do
      allow(machine.state).to receive(:id).and_return(:not_running)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error

      expect { subject.send(:run_remote, shell_config, on_error) }.
        to raise_error(Vagrant::Errors::TriggersGuestNotRunning)
    end

    it "continues on if guest is not running but is configured to continue on error" do
      allow(machine.state).to receive(:id).and_return(:not_running)

      allow(env).to receive(:root_path).and_return("/vagrant/home")
      allow(FileUtils).to receive(:chmod).and_return(true)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error

      subject.send(:run_remote, shell_config, on_error)
    end

    it "calls the provision function on the shell provisioner" do
      allow(machine.state).to receive(:id).and_return(:running)
      allow(provision).to receive(:provision).and_return("Provision!")
      allow(VagrantPlugins::Shell::Provisioner).to receive(:new).
        and_return(provision)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error

      subject.send(:run_remote, shell_config, on_error)
    end

    it "continues on if provision fails" do
      allow(machine.state).to receive(:id).and_return(:running)
      allow(provision).to receive(:provision).and_raise("Nope!")
      allow(VagrantPlugins::Shell::Provisioner).to receive(:new).
        and_return(provision)

      trigger = trigger_run.before_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error

      subject.send(:run_remote, shell_config, on_error)
    end

    it "fails if it encounters an error" do
      allow(machine.state).to receive(:id).and_return(:running)
      allow(provision).to receive(:provision).and_raise("Nope!")
      allow(VagrantPlugins::Shell::Provisioner).to receive(:new).
        and_return(provision)

      trigger = trigger_run.after_triggers.first
      shell_config = trigger.run_remote
      on_error = trigger.on_error

      expect { subject.send(:run_remote, shell_config, on_error) }.
        to raise_error("Nope!")
    end
  end
end
