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
    expect(app).to receive(:call).with(env)
    subject.call(env)
  end

  it "does nothing if the host doesn't support pruning NFS" do
    allow(host).to receive(:capability?).with(:nfs_prune).and_return(false)
    expect(host).to receive(:capability).never
    expect(app).to receive(:call).with(env)

    subject.call(env)
  end

  it "prunes the NFS entries if valid IDs are given" do
    env[:nfs_valid_ids] = [1,2,3]

    allow(host).to receive(:capability?).with(:nfs_prune).and_return(true)
    expect(host).to receive(:capability).with(:nfs_prune, machine.ui, [1,2,3]).ordered
    expect(app).to receive(:call).with(env).ordered

    subject.call(env)
  end
end
