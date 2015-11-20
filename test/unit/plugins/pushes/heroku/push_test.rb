require_relative "../../../base"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/pushes/heroku/push")

describe VagrantPlugins::HerokuPush::Push do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/heroku/locales/en.yml")
    I18n.reload!
  end

  let(:env) { isolated_environment }
  let(:config) do
    double("config",
      app:     "bacon",
      dir:     "lib",
      git_bin: "git",
      remote:  "heroku",
    )
  end

  subject { described_class.new(env, config) }

  describe "#push" do
    let(:branch) { "master" }
    let(:dir) { "#{root_path}/#{config.dir}" }

    let(:root_path) do
      next "/handy/dandy" if !Vagrant::Util::Platform.windows?
      "C:/handy/dandy" 
    end

    before do
      allow(subject).to receive(:git_branch)
        .and_return(branch)
      allow(subject).to receive(:verify_git_bin!)
      allow(subject).to receive(:verify_git_repo!)
      allow(subject).to receive(:has_git_remote?)
      allow(subject).to receive(:add_heroku_git_remote)
      allow(subject).to receive(:git_push_heroku)
      allow(subject).to receive(:execute!)

      allow(env).to receive(:root_path)
        .and_return(root_path)
    end

    it "verifies the git bin is present" do
      expect(subject).to receive(:verify_git_bin!)
        .with(config.git_bin)
      subject.push
    end

    it "verifies the directory is a git repo" do
      expect(subject).to receive(:verify_git_repo!)
        .with(dir)
      subject.push
    end

    context "when the heroku remote exists" do
      before do
        allow(subject).to receive(:has_git_remote?)
          .and_return(true)
      end

      it "does not add the heroku remote" do
        expect(subject).to_not receive(:add_heroku_git_remote)
        subject.push
      end
    end

    context "when the heroku remote does not exist" do
      before do
        allow(subject).to receive(:has_git_remote?)
          .and_return(false)
      end

      it "adds the heroku remote" do
        expect(subject).to receive(:add_heroku_git_remote)
          .with(config.remote, config.app, dir)
        subject.push
      end
    end

    it "pushes to heroku" do
      expect(subject).to receive(:git_push_heroku)
        .with(config.remote, branch, dir)
      subject.push
    end
  end

  describe "#verify_git_bin!" do
    context "when git does not exist" do
      before do
        allow(Vagrant::Util::Which).to receive(:which)
          .with("git")
          .and_return(nil)
      end

      it "raises an exception" do
        expect {
          subject.verify_git_bin!("git")
        } .to raise_error(VagrantPlugins::HerokuPush::Errors::GitNotFound) { |error|
          expect(error.message).to eq(I18n.t("heroku_push.errors.git_not_found",
            bin: "git",
          ))
        }
      end
    end

    context "when git exists" do
      before do
        allow(Vagrant::Util::Which).to receive(:which)
          .with("git")
          .and_return("git")
      end

      it "does not raise an exception" do
        expect { subject.verify_git_bin!("git") }.to_not raise_error
      end
    end
  end

  describe "#verify_git_repo!" do
    context "when the path is a git repo" do
      before do
        allow(File).to receive(:directory?)
          .with("/repo/path/.git")
          .and_return(false)
      end

      it "raises an exception" do
        expect {
          subject.verify_git_repo!("/repo/path")
        } .to raise_error(VagrantPlugins::HerokuPush::Errors::NotAGitRepo) { |error|
          expect(error.message).to eq(I18n.t("heroku_push.errors.not_a_git_repo",
            path: "/repo/path",
          ))
        }
      end
    end

    context "when the path is not a git repo" do
      before do
        allow(File).to receive(:directory?)
          .with("/repo/path/.git")
          .and_return(true)
      end

      it "does not raise an exception" do
        expect { subject.verify_git_repo!("/repo/path") }.to_not raise_error
      end
    end
  end

  describe "#git_push_heroku" do
    let(:dir) { "." }

    before { allow(subject).to receive(:execute!) }

    it "executes the proper command" do
      expect(subject).to receive(:execute!)
        .with("git",
          "--git-dir", "#{dir}/.git",
          "--work-tree", dir,
          "push", "bacon", "hamlet:master",
        )
      subject.git_push_heroku("bacon", "hamlet", dir)
    end
  end

  describe "#has_git_remote?" do
    let(:dir) { "." }

    let(:process) do
      double("process",
        stdout: "origin\r\nbacon\nhello"
      )
    end

    before do
      allow(subject).to receive(:execute!)
        .and_return(process)
    end

    it "executes the proper command" do
      expect(subject).to receive(:execute!)
        .with("git",
          "--git-dir", "#{dir}/.git",
          "--work-tree", dir,
          "remote",
        )
      subject.has_git_remote?("bacon", dir)
    end

    it "returns true when the remote exists" do
      expect(subject.has_git_remote?("origin", dir)).to be(true)
      expect(subject.has_git_remote?("bacon", dir)).to be(true)
      expect(subject.has_git_remote?("hello", dir)).to be(true)
    end

    it "returns false when the remote does not exist" do
      expect(subject.has_git_remote?("nope", dir)).to be(false)
    end
  end

  describe "#add_heroku_git_remote" do
    let(:dir) { "." }

    before do
      allow(subject).to receive(:execute!)
      allow(subject).to receive(:heroku_git_url)
        .with("app")
        .and_return("HEROKU_URL")
    end

    it "executes the proper command" do
      expect(subject).to receive(:execute!)
        .with("git",
          "--git-dir", "#{dir}/.git",
          "--work-tree", dir,
          "remote", "add", "bacon", "HEROKU_URL",
        )
      subject.add_heroku_git_remote("bacon", "app", dir)
    end
  end

  describe "#interpret_app" do
    it "returns the basename of the directory" do
      expect(subject.interpret_app("/foo/bar/blitz")).to eq("blitz")
    end
  end

  describe "#heroku_git_url" do
    it "returns the proper string" do
      expect(subject.heroku_git_url("bacon"))
        .to eq("git@heroku.com:bacon.git")
    end
  end

  describe "#git_dir" do
    it "returns the .git directory for the path" do
      expect(subject.git_dir("/path")).to eq("/path/.git")
    end
  end

  describe "#git_branch" do
    let(:stdout) { "" }
    let(:process) { double("process", stdout: stdout) }

    before do
      allow(subject).to receive(:execute!)
        .and_return(process)
    end

    let(:branch) { subject.git_branch("/path") }

    context "when the branch is not prefixed" do
      let(:stdout) { "bacon" }

      it "returns the correct name" do
        expect(branch).to eq("bacon")
      end
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
        klass = VagrantPlugins::HerokuPush::Errors::CommandFailed
        cmd = ["foo", "bar"]

        expect { subject.execute!(*cmd) }.to raise_error(klass) { |error|
          expect(error.message).to eq(I18n.t("heroku_push.errors.command_failed",
            cmd:    cmd.join(" "),
            stdout: stdout,
            stderr: stderr,
          ))
        }
      end
    end
  end
end
