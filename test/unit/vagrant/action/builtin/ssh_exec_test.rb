require File.expand_path("../../../../base", __FILE__)

require "vagrant/util/ssh"

describe Vagrant::Action::Builtin::SSHExec do
  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine } }
  let(:machine) do
    result = double("machine")
    allow(result).to receive(:communicator_info).and_return(machine_communicator_info)
    result
  end
  let(:machine_communicator_info) { {} }
  let(:ssh_klass) { Vagrant::Util::SSH }

  before(:each) do
    # Stub the methods so that even if we test incorrectly, no side
    # effects actually happen.
    allow(ssh_klass).to receive(:check_key_permissions)
    allow(ssh_klass).to receive(:exec)
  end

  it "should raise an exception if SSH is not ready" do
    not_ready_machine = double("machine")
    allow(not_ready_machine).to receive(:communicator_info).and_return(nil)

    env[:machine] = not_ready_machine
    expect { described_class.new(app, env).call(env) }.
      to raise_error(Vagrant::Errors::SSHNotReady)
  end

  it "should check key permissions then exec" do
    key_path = "/foo"
    machine_communicator_info[:private_key_path] = [key_path]

    expect(ssh_klass).to receive(:check_key_permissions).
      with(Pathname.new(key_path)).
      once.
      ordered

    expect(ssh_klass).to receive(:exec).
      with(machine_communicator_info, nil).
      once.
      ordered

    described_class.new(app, env).call(env)
  end

  it "should exec with the SSH info in the env if given" do
    communicator_info = { foo: :bar }

    expect(ssh_klass).to receive(:exec).
      with(communicator_info, nil)

    env[:ssh_info] = communicator_info
    described_class.new(app, env).call(env)
  end

  it "should exec with the options given in `ssh_opts`" do
    ssh_opts = { foo: :bar }

    expect(ssh_klass).to receive(:exec).
      with(machine_communicator_info, ssh_opts)

    env[:ssh_opts] = ssh_opts
    described_class.new(app, env).call(env)
  end
end
