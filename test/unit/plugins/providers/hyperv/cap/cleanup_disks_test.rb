require Vagrant.source_root.join("plugins/providers/hyperv/cap/cleanup_disks")

describe VagrantPlugins::HyperV::Cap::CleanupDisks do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:driver) { double("driver") }

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m).to receive(:state).and_return(state)
    end
  end

  let(:state) do
    double(:state)
  end

  let(:subject) { described_class }

  let(:disk_meta_file) { {disk: [], floppy: [], dvd: []} }
  let(:defined_disks) { {} }

  before do
    allow(Vagrant::Util::Experimental).to receive(:feature_enabled?).and_return(true)
  end

  context "#cleanup_disks" do
  end

  context "#handle_cleanup_disk" do
  end
end
