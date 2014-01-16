require_relative "../../../base"

require Vagrant.source_root.join("plugins/synced_folders/nfs/action_cleanup")

describe VagrantPlugins::SyncedFolderNFS::ActionCleanup do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:host)    { double("host") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:app) { lambda {} }
  let(:env) { {
    machine: machine,
  } }

  subject { described_class.new(app, env) }

  before do
    machine.env.stub(host: host)
  end

  it "does nothing if there are no valid IDs" do
    app.should_receive(:call).with(env)
    subject.call(env)
  end

  it "does nothing if the host doesn't support pruning NFS" do
    host.stub(:capability?).with(:nfs_prune).and_return(false)
    host.should_receive(:capability).never
    app.should_receive(:call).with(env)

    subject.call(env)
  end

  it "prunes the NFS entries if valid IDs are given" do
    env[:nfs_valid_ids] = [1,2,3]

    host.stub(:capability?).with(:nfs_prune).and_return(true)
    host.should_receive(:capability).with(:nfs_prune, machine.ui, [1,2,3]).ordered
    app.should_receive(:call).with(env).ordered

    subject.call(env)
  end
end
