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

  it "should check key permissions then exec" do
    pending
  end

  it "should exec with the options given in `ssh_opts`" do
    pending
  end
end
