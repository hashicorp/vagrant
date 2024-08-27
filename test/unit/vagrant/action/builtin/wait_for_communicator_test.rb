require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::WaitForCommunicator do
  let(:app) { lambda { |env| } }
  let(:ui) { lambda { |env| } }
  let(:env) { { machine: machine, ui: ui } }

  let(:vm) do
    double("vm",
      communicator: nil
    )
  end

  # Configuration mock
  let(:config) { double("config", vm: vm) }

  # Communicate mock
  let(:communicate) { double("communicate") }

  let(:state) { double("state") }

  let(:ui) { Vagrant::UI::Silent.new }

  let(:machine) do
    double("machine",
      config: config,
      communicate: communicate, 
      state: state,)
  end

  before do 
    allow(vm).to receive(:boot_timeout).and_return(1)
    allow(communicate).to receive(:wait_for_ready).with(1).and_return(true)
  end

  it "raise an error if a bad state is encountered" do
    allow(state).to receive(:id).and_return(:stopped)
    
    expect { described_class.new(app, env, [:running]).call(env) }.
    to raise_error(Vagrant::Errors::VMBootBadState)
  end

  it "raise an error if the vm doesn't boot" do
    allow(communicate).to receive(:wait_for_ready).and_return(false)
    allow(state).to receive(:id).and_return(:running)
    
    expect { described_class.new(app, env, [:running]).call(env) }.
    to raise_error(Vagrant::Errors::VMBootTimeout)
  end

  it "succeed when a valid state is encountered" do
    allow(communicate).to receive(:wait_for_ready).and_return(true)
    allow(state).to receive(:id).and_return(:running)
    
    expect { described_class.new(app, env, [:running]).call(env) }.
    to_not raise_error
  end
end