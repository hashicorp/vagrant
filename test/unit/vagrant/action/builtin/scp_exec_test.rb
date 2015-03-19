require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::SCPExec do
  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine } }
  let(:machine) do
    result = double("machine")
    allow(result).to receive(:ssh_info).and_return(machine_ssh_info)
    result
  end
  let(:machine_ssh_info) { {} }
  let(:scp_klass) { Vagrant::Util::SCP }

  it "raises an exception if SSH is not ready" do
    not_ready_machine = double("machine")
    allow(not_ready_machine).to receive(:ssh_info).and_return(nil)

    env[:machine] = not_ready_machine
    expect { described_class.new(app, env).call(env) }.
      to raise_error(Vagrant::Errors::SSHNotReady)
  end

  it "raises an exception if a destination or a source are not given" do
    ssh_info     = { foo: :bar }
    expect { described_class.new(app, env).call(env) }.
      to raise_error(Vagrant::Errors::SCPEmptySourceOrDestination)
  end
end

