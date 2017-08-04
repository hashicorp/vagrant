require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/command/exec"

describe VagrantPlugins::DockerProvider::Command::Exec do
  include_context "unit"
  include_context "command plugin helpers"

  let(:sandbox) do
    isolated_environment
  end

  let(:argv) { [] }
  let(:env) { sandbox.create_vagrant_env }

  let(:vagrantfile_path) { File.join(env.cwd, "Vagrantfile") }

  subject { described_class.new(argv, env) }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("templates/locales/providers_docker.yml")
    I18n.reload!
  end

  before do
    allow(Vagrant.plugin("2").manager).to receive(:commands).and_return({})
    allow(subject).to receive(:exec_command)
  end

  after do
    sandbox.close
  end

  describe "#execute" do
    describe "without a command" do
      let(:argv) { [] }

      it "raises an error" do
        expect {
          subject.execute
        }.to raise_error(VagrantPlugins::DockerProvider::Errors::ExecCommandRequired)
      end
    end
  end
end
