require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/docker/provisioner")

describe VagrantPlugins::DockerProvisioner::Provisioner do
  include_context "unit"
  subject { described_class.new(machine, config, installer, client) }

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
  let(:client)       { double("client") }
  let(:installer)    { double("installer") }
  let(:hook)         { double("hook") }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:guest).and_return(guest)

    allow(communicator).to receive(:execute).and_return(true)
    allow(communicator).to receive(:upload).and_return(true)

    allow(guest).to receive(:capability?).and_return(false)
    allow(guest).to receive(:capability).and_return(false)

    allow(client).to receive(:start_service).and_return(true)
    allow(client).to receive(:daemon_running?).and_return(true)

    allow(config).to receive(:images).and_return(Set.new)
    allow(config).to receive(:build_images).and_return(Set.new)
    allow(config).to receive(:containers).and_return(Hash.new)
  end

  describe "#provision" do
    let(:provisioner) do
      prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("spec-test", :shell)
      prov.config = {}
      prov
    end

    it "invokes a post_install_provisioner if defined and docker is installed" do
      allow(installer).to receive(:ensure_installed).and_return(true)
      allow(config).to receive(:post_install_provisioner).and_return(provisioner)
      allow(machine).to receive(:env).and_return(iso_env)
      allow(machine.env).to receive(:hook).and_return(true)

      expect(machine.env).to receive(:hook).with(:run_provisioner, anything)
      subject.provision()
    end

    it "does not invoke post_install_provisioner if not defined" do
      allow(installer).to receive(:ensure_installed).and_return(true)
      allow(config).to receive(:post_install_provisioner).and_return(nil)
      allow(machine).to receive(:env).and_return(iso_env)
      allow(machine.env).to receive(:hook).and_return(true)

      expect(machine.env).not_to receive(:hook).with(:run_provisioner, anything)
      subject.provision()
    end

    it "raises an error if docker daemon isn't running" do
      allow(installer).to receive(:ensure_installed).and_return(false)
      allow(client).to receive(:start_service).and_return(false)
      allow(client).to receive(:daemon_running?).and_return(false)

      expect { subject.provision() }.
        to raise_error(VagrantPlugins::DockerProvisioner::DockerError)
    end
  end

end
