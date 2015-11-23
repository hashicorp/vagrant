require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Action::NetworkFixIPv6 do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy)
  end

  let(:env) {{ machine: machine }}
  let(:app) { lambda { |*args| }}

  subject { described_class.new(app, env) }

  it "ignores nil IP addresses" do
    allow(machine.config.vm).to receive(:networks)
      .and_return(private_network: { ip: nil })
    expect { subject.call(env) }.to_not raise_error
  end

  it "blank nil IP addresses" do
    allow(machine.config.vm).to receive(:networks)
      .and_return(private_network: { ip: "" })
    expect { subject.call(env) }.to_not raise_error
  end
end
