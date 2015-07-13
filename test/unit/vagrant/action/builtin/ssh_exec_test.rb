require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::SSHExec do
  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine } }
  let(:machine) do
    result = double("machine")
    allow(result).to receive(:ssh_info).and_return(machine_ssh_info)
    result
  end
  let(:machine_ssh_info) { {} }
  let(:ssh_klass) { Vagrant::Util::SSH }

  before(:each) do
    # Stub the methods so that even if we test incorrectly, no side
    # effects actually happen.
    allow(ssh_klass).to receive(:exec)
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

    expect(ssh_klass).to receive(:exec).
      with(ssh_info, nil)

    env[:ssh_info] = ssh_info
    described_class.new(app, env).call(env)
  end

  it "should exec with the options given in `ssh_opts`" do
    ssh_opts = { foo: :bar }

    expect(ssh_klass).to receive(:exec).
      with(machine_ssh_info, ssh_opts)

    env[:ssh_opts] = ssh_opts
    described_class.new(app, env).call(env)
  end
end
