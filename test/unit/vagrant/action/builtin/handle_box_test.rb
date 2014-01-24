require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::HandleBox do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) { {
    machine: machine,
    ui: Vagrant::UI::Silent.new,
  } }

  subject { described_class.new(app, env) }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  it "works if there is no box set" do
    machine.config.vm.box = nil
    machine.config.vm.box_url = nil

    app.should_receive(:call).with(env)

    subject.call(env)
  end
end
