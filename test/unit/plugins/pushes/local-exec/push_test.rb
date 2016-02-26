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
      args: "some args",
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
          .with(config.inline, config.args)
        subject.push
      end
    end

    context "when script is given" do
      before { allow(config).to receive(:script).and_return("foo.sh") }

      it "executes the script" do
        expect(subject).to receive(:execute_script!)
          .with(config.script, config.args)
        subject.push
      end
    end
  end

  describe "#execute_inline!" do
    before { allow(subject).to receive(:execute_script!) }

    it "writes the script to a tempfile" do
      expect(Tempfile).to receive(:new).and_call_original
      subject.execute_inline!("echo", config.args)
    end

    it "executes the script" do
      expect(subject).to receive(:execute_script!)
      subject.execute_inline!("echo", config.args)
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
      subject.execute_script!("./foo.sh", nil)
    end

    it "makes the file executable" do
      expect(FileUtils).to receive(:chmod)
        .with("+x", File.expand_path("foo.sh", env.root_path))
      subject.execute_script!("./foo.sh", config.args)
    end

    it "calls execute!" do
      expect(subject).to receive(:execute!)
        .with(File.expand_path("foo.sh", env.root_path))
      subject.execute_script!("./foo.sh", nil)
    end

    context "when args is given" do
      it "passes string args to execute!" do
        expect(subject).to receive(:execute!)
          .with(File.expand_path("foo.sh", env.root_path) + " " + config.args)
        subject.execute_script!("./foo.sh", config.args)
      end

      it "passes array args as string to execute!" do
        expect(subject).to receive(:execute!)
          .with(File.expand_path("foo.sh", env.root_path) + " \"one\" \"two\" \"three\"")
        subject.execute_script!("./foo.sh", ["one", "two", "three"])
      end
    end
  end

  describe "#execute!" do
    it "uses exec on unix" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(false)
      expect(Vagrant::Util::SafeExec).to receive(:exec)
      expect { subject.execute! }.to_not raise_error
    end

    it "uses subprocess on windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      result = double("result", exit_code: 0)
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(result)
      expect { subject.execute! }.to raise_error { |e|
        expect(e).to be_a(SystemExit)
      }
    end
  end
end
