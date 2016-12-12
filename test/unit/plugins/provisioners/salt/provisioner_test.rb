require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/salt/provisioner")

describe VagrantPlugins::Salt::Provisioner do
  include_context "unit"

  subject { described_class.new(machine, config) }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)       { double("config") }
  let(:communicator) { double("comm") }
  let(:guest)        { double("guest") }

  before do
    machine.stub(communicate: communicator)
    machine.stub(guest: guest)

    communicator.stub(execute: true)
    communicator.stub(upload: true)

    guest.stub(capability?: false)
  end

  describe "#provision" do

  end
end
