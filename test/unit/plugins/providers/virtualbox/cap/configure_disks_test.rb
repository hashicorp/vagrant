require_relative "../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/cap/configure_disks")

describe VagrantPlugins::ProviderVirtualBox::Cap::ConfigureDisks do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m).to receive(:state).and_return(state)
    end
  end

  let(:state) do
    double(:state)
  end

  describe "#configure_disks" do
  end
end
