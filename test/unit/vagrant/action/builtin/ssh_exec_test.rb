require File.expand_path("../../../../base", __FILE__)

require "vagrant/util/ssh"

describe Vagrant::Action::Builtin::SSHExec do
  let(:app) { lambda { |env| } }
  let(:env) { { :machine => machine } }
  let(:machine) do
    result = double("machine")
    result.stub(:ssh_info).and_return(machine_ssh_info)
    result
  end
  let(:machine_ssh_info) { {} }
  let(:ssh_klass) { Vagrant::Util::SSH }

  before(:each) do
    # Stub the methods so that even if we test incorrectly, no side
    # effects actually happen.
    ssh_klass.stub(:check_key_permissions)
    ssh_klass.stub(:exec)
  end

  it "should raise an exception if SSH is not ready" do
    not_ready_machine = double("machine")
    not_ready_machine.stub(:ssh_info).and_return(nil)

    env[:machine] = not_ready_machine
    expect { described_class.new(app, env).call(env) }.
      to raise_error(Vagrant::Errors::SSHNotReady)
  end

  it "should check key permissions then exec" do
    machine_ssh_info[:private_key_path] = "/foo"

    ssh_klass.should_receive(:check_key_permissions).
      with(Pathname.new(machine_ssh_info[:private_key_path])).
      once.
      ordered

    ssh_klass.should_receive(:exec).
      with(machine_ssh_info, nil).
      once.
      ordered

    described_class.new(app, env).call(env)
  end

  it "should exec with the options given in `ssh_opts`" do
    ssh_opts = { :foo => :bar }

    ssh_klass.should_receive(:exec).
      with(machine_ssh_info, ssh_opts)

    env[:ssh_opts] = ssh_opts
    described_class.new(app, env).call(env)
  end
end
