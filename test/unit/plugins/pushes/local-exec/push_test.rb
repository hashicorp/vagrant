require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/local-exec/push")

describe VagrantPlugins::LocalExecPush::Push do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/local-exec/locales/en.yml")
    I18n.reload!
  end

  let(:env) { isolated_environment }
  let(:config) do
    double("config",
      command: "echo",
    )
  end

  subject { described_class.new(env, config) }

  describe "#push" do
    before do
      allow(subject).to receive(:execute!)
    end

    it "executes the command" do
      expect(subject).to receive(:execute!)
        .with(config.command)
      subject.push
    end
  end

  describe "#execute!" do
    let(:exit_code) { 0 }
    let(:stdout) { "This is the output" }
    let(:stderr) { "This is the errput" }

    let(:process) do
      double("process",
        exit_code: exit_code,
        stdout:    stdout,
        stderr:    stderr,
      )
    end

    before do
      allow(Vagrant::Util::Subprocess).to receive(:execute)
        .and_return(process)
    end

    it "creates a subprocess" do
      expect(Vagrant::Util::Subprocess).to receive(:execute)
      expect { subject.execute! }.to_not raise_error
    end

    it "returns the resulting process" do
      expect(subject.execute!).to be(process)
    end

    context "when the exit code is non-zero" do
      let(:exit_code) { 1 }

      it "raises an exception" do
        klass = VagrantPlugins::LocalExecPush::Errors::CommandFailed
        cmd = ["foo", "bar"]

        expect { subject.execute!(*cmd) }.to raise_error(klass) { |error|
          expect(error.message).to eq(I18n.t("local_exec_push.errors.command_failed",
            cmd:    cmd.join(" "),
            stdout: stdout,
            stderr: stderr,
          ))
        }
      end
    end
  end
end
