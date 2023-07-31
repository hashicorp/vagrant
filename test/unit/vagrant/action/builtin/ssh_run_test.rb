# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::SSHRun do
  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine, tty: true } }

  # SSH configuration information mock
  let(:ssh) do
    double("ssh",
      timeout: 1,
      host: nil,
      port: 5986,
      guest_port: 5986,
      pty: false,
      keep_alive: false,
      insert_key: false,
      shell: 'bash -l'
    )
  end

  let(:vm) do
    double("vm",
      communicator: nil
    )
  end

  # Configuration mock
  let(:config) { double("config", ssh: ssh, vm: vm) }

  let(:machine) do
    double("machine",
      config: config,)
  end

  let(:machine_ssh_info) { {} }
  let(:ssh_klass) { Vagrant::Util::SSH }

  before(:each) do
    # Stub the methods so that even if we test incorrectly, no side
    # effects actually happen.
    allow(ssh_klass).to receive(:exec)
    allow(machine).to receive(:ssh_info).and_return(machine_ssh_info)
  end

  it "should raise an exception if SSH is not ready" do
    not_ready_machine = double("machine")
    allow(not_ready_machine).to receive(:ssh_info).and_return(nil)

    env[:machine] = not_ready_machine
    expect { described_class.new(app, env).call(env) }.
      to raise_error(Vagrant::Errors::SSHNotReady)
  end

  it "should exec with the SSH info in the env if given" do
    ssh_info = { foo: :bar }
    opts = {:extra_args=>["-t", "bash -l -c 'echo test'"], :subprocess=>true}

    expect(ssh_klass).to receive(:exec).
      with(ssh_info, opts)

    env[:ssh_info] = ssh_info
    env[:ssh_run_command] = "echo test"
    described_class.new(app, env).call(env)
  end

  it "should exec with the SSH info in the env if given and disable tty" do
    ssh_info = { foo: :bar }
    opts = {:extra_args=>["bash -l -c 'echo test'"], :subprocess=>true}
    env[:tty] = false

    expect(ssh_klass).to receive(:exec).
      with(ssh_info, opts)

    env[:ssh_info] = ssh_info
    env[:ssh_run_command] = "echo test"
    described_class.new(app, env).call(env)
  end

  it "should exec with the options given in `ssh_opts`" do
    ssh_opts = { foo: :bar }

    expect(ssh_klass).to receive(:exec).
      with(machine_ssh_info, ssh_opts)

    env[:ssh_opts] = ssh_opts
    env[:ssh_run_command] = "echo test"
    described_class.new(app, env).call(env)
  end

  context "when using the WinSSH communicator" do
    let(:winssh) { double("winssh", shell: "foo") }

    before do
      expect(vm).to receive(:communicator).and_return(:winssh)
      expect(config).to receive(:winssh).and_return(winssh)
      env[:tty] = nil
    end

    it "should use the WinSSH shell for running ssh commands" do
      ssh_info = { foo: :bar }
      opts = {:extra_args=>["foo -c 'dir'"], :subprocess=>true}

      expect(ssh_klass).to receive(:exec).
        with(ssh_info, opts)

      env[:ssh_info] = ssh_info
      env[:ssh_run_command] = "dir"
      described_class.new(app, env).call(env)
    end

    context "when shell is cmd" do
      before do
        expect(winssh).to receive(:shell).and_return('cmd')
      end

      it "should use appropriate options for cmd" do
        ssh_info = { foo: :bar }
        opts = {:extra_args=>["cmd /C dir "], :subprocess=>true}

        expect(ssh_klass).to receive(:exec).
          with(ssh_info, opts)

        env[:ssh_info] = ssh_info
        env[:ssh_run_command] = "dir"
        described_class.new(app, env).call(env)
      end
    end

    context "when shell is powershell" do
      before do
        expect(winssh).to receive(:shell).and_return('powershell')
      end

      it "should base64 encode the command" do
        ssh_info = { foo: :bar }
        encoded_command = "JABQAHIAbwBnAHIAZQBzAHMAUAByAGUAZgBlAHIAZQBuAGMAZQAgAD0AIAAiAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUAIgA7ACAAZABpAHIA"
        opts = {:extra_args=>["powershell -encodedCommand #{encoded_command}"], :subprocess=>true}

        expect(ssh_klass).to receive(:exec).
          with(ssh_info, opts)

        env[:ssh_info] = ssh_info
        env[:ssh_run_command] = "dir"
        described_class.new(app, env).call(env)
      end
    end
  end
end
