require_relative "../../../../base"

require Vagrant.source_root.join("plugins/synced_folders/rsync/command/rsync")

describe VagrantPlugins::SyncedFolderRSync::Command::Rsync do
  include_context "unit"

  let(:argv) { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:communicator) { double("comm") }

  let(:synced_folders) { {} }

  let(:helper_class) { VagrantPlugins::SyncedFolderRSync::RsyncHelper }

  subject do
    described_class.new(argv, iso_env).tap do |s|
      allow(s).to receive(:synced_folders).and_return(synced_folders)
    end
  end

  before do
    iso_env.machine_names.each do |name|
      m = iso_env.machine(name, iso_env.default_provider)
      allow(m).to receive(:communicate).and_return(communicator)
    end
  end

  describe "#execute" do
    context "with a single machine" do
      let(:ssh_info) {{
        private_key_path: [],
      }}

      let(:machine) { iso_env.machine(iso_env.machine_names[0], iso_env.default_provider) }

      before do
        allow(communicator).to receive(:ready?).and_return(true)
        allow(machine).to receive(:ssh_info).and_return(ssh_info)

        synced_folders[:rsync] = [
          [:one, {}],
          [:two, {}],
        ]
      end

      it "doesn't sync if communicator isn't ready and exits with 1" do
        allow(communicator).to receive(:ready?).and_return(false)

        expect(helper_class).to receive(:rsync_single).never

        expect(subject.execute).to eql(1)
      end

      it "rsyncs each folder and exits successfully" do
        synced_folders[:rsync].each do |_, opts|
          expect(helper_class).to receive(:rsync_single).
            with(machine, ssh_info, opts).
            ordered
        end

        expect(subject.execute).to eql(0)
      end
    end
  end
end
