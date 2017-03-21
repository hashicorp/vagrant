require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/up/command")

describe VagrantPlugins::CommandUp::Command do
  include_context "unit"

  let(:argv)     { [] }
  let(:vagrantfile_content){ "" }
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile(vagrantfile_content)
    env.create_vagrant_env
  end

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  before do
    iso_env.stub(action_runner: action_runner)
  end

  context "with no argument" do
    let(:vagrantfile_content){ "Vagrant.configure(2){|config| config.vm.box = 'dummy'}" }

    it "should bring up the default box" do
      batch = double("environment_batch")
      expect(iso_env).to receive(:batch).and_yield(batch)
      expect(batch).to receive(:action).with(anything, :up, anything)
      subject.execute
    end

    context "with VAGRANT_DEFAULT_PROVIDER set" do
      before do
        if ENV["VAGRANT_DEFAULT_PROVIDER"]
          @original_default = ENV["VAGRANT_DEFAULT_PROVIDER"]
        end
        ENV["VAGRANT_DEFAULT_PROVIDER"] = "unknown"
      end
      after do
        if @original_default
          ENV["VAGRANT_DEFAULT_PROVIDER"] = @original_default
        else
          ENV.delete("VAGRANT_DEFAULT_PROVIDER")
        end
      end

      it "should attempt to use dummy provider" do
        expect{ subject.execute }.to raise_error
      end

      context "with --provider set" do
        let(:argv){ ["--provider", "dummy"] }

        it "should only use provider explicitly set" do
          batch = double("environment_batch")
          expect(iso_env).to receive(:batch).and_yield(batch)
          expect(batch).to receive(:action).with(anything, :up, anything)
          subject.execute
        end
      end
    end
  end
end
