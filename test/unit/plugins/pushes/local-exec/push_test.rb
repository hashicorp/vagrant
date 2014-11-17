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
      script: nil,
      inline: nil,
    )
  end

  subject { described_class.new(env, config) }

  before do
    allow(env).to receive(:root_path)
      .and_return(File.expand_path("..", __FILE__))
  end

  describe "#push" do
    before do
      allow(subject).to receive(:execute_inline!)
      allow(subject).to receive(:execute_script!)
      allow(subject).to receive(:execute!)
    end

    context "when inline is given" do
      before { allow(config).to receive(:inline).and_return("echo") }

      it "executes the inline script" do
        expect(subject).to receive(:execute_inline!)
          .with(config.inline)
        subject.push
      end
    end

    context "when script is given" do
      before { allow(config).to receive(:script).and_return("foo.sh") }

      it "executes the script" do
        expect(subject).to receive(:execute_script!)
          .with(config.script)
        subject.push
      end
    end
  end

  describe "#execute_inline!" do
    before { allow(subject).to receive(:execute_script!) }

    it "writes the script to a tempfile" do
      expect(Tempfile).to receive(:new).and_call_original
      subject.execute_inline!("echo")
    end

    it "executes the script" do
      expect(subject).to receive(:execute_script!)
      subject.execute_inline!("echo")
    end
  end

  describe "#execute_script!" do
    before do
      allow(subject).to receive(:execute!)
      allow(FileUtils).to receive(:chmod)
    end

    it "expands the path relative to the machine root" do
      expect(subject).to receive(:execute!)
        .with(File.expand_path("foo.sh", env.root_path))
      subject.execute_script!("./foo.sh")
    end

    it "makes the file executable" do
      expect(FileUtils).to receive(:chmod)
        .with("+x", File.expand_path("foo.sh", env.root_path))
      subject.execute_script!("./foo.sh")
    end

    it "calls execute!" do
      expect(subject).to receive(:execute!)
        .with(File.expand_path("foo.sh", env.root_path))
      subject.execute_script!("./foo.sh")
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
