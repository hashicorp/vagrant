require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/push/command")

describe VagrantPlugins::CommandPush::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:env) do
    isolated_environment.tap do |env|
      env.vagrantfile("")
      env.create_vagrant_env
    end
  end

  let(:argv)   { [] }
  let(:pushes) { {} }

  subject { described_class.new(argv, env) }

  before do
    Vagrant.plugin("2").manager.stub(pushes: pushes)
  end

  describe "#execute" do
    before do
      allow(subject).to receive(:validate_pushes!)
        .and_return([:noop])
      allow(env).to receive(:pushes)
      allow(env).to receive(:push)
    end

    it "validates the pushes" do
      expect(subject).to receive(:validate_pushes!)
        .with(nil, argv, kind_of(Hash))
        .once
      subject.execute
    end

    it "parses arguments" do
      list = ["noop", "ftp"]
      instance = described_class.new(list, env)
      expect(instance).to receive(:validate_pushes!)
        .with(nil, list, kind_of(Hash))
        .and_return([])
      instance.execute
    end

    it "parses options" do
      instance = described_class.new(["--all"], env)
      expect(instance).to receive(:validate_pushes!)
        .with(nil, argv, all: true)
        .and_return([])
      instance.execute
    end

    it "delegates to Environment#push" do
      expect(env).to receive(:push).once
      subject.execute
    end
  end

  describe "#validate_pushes!" do
    context "when there are no pushes defined" do
      let(:pushes) { [] }

      context "when a strategy is given" do
        it "raises an exception" do
          expect { subject.validate_pushes!(pushes, :noop) }
            .to raise_error(Vagrant::Errors::PushesNotDefined)
        end
      end

      context "when no strategy is given" do
        it "raises an exception" do
          expect { subject.validate_pushes!(pushes) }
            .to raise_error(Vagrant::Errors::PushesNotDefined)
        end
      end
    end

    context "when there is one push defined" do
      let(:noop) { double("noop") }
      let(:pushes) { [:noop] }

      context "when a strategy is given" do
        context "when that strategy is not defined" do
          it "raises an exception" do
            expect { subject.validate_pushes!(pushes, :bacon) }
              .to raise_error(Vagrant::Errors::PushStrategyNotDefined)
          end
        end

        context "when that strategy is defined" do
          it "returns that push" do
            expect(subject.validate_pushes!(pushes, :noop)).to eq([:noop])
          end
        end
      end

      context "when no strategy is given" do
        it "returns the push" do
          expect(subject.validate_pushes!(pushes)).to eq([:noop])
        end
      end

      context "when --all is given" do
        it "returns the push" do
          expect(subject.validate_pushes!(pushes, [], all: true))
            .to eq([:noop])
        end
      end
    end

    context "when there are multiple pushes defined" do
      let(:noop) { double("noop") }
      let(:ftp)  { double("ftp") }
      let(:pushes) { [:noop, :ftp] }

      context "when a strategy is given" do
        context "when that strategy is not defined" do
          it "raises an exception" do
            expect { subject.validate_pushes!(pushes, :bacon) }
              .to raise_error(Vagrant::Errors::PushStrategyNotDefined)
          end
        end

        context "when that strategy is defined" do
          it "returns the strategy" do
            expect(subject.validate_pushes!(pushes, :noop)).to eq([:noop])
            expect(subject.validate_pushes!(pushes, :ftp)).to eq([:ftp])
          end
        end
      end

      context "when multiple strategies are given" do
        it "returns the pushes" do
          expect(subject.validate_pushes!(pushes, [:noop, :ftp]))
            .to eq([:noop, :ftp])
        end
      end

      context "when no strategy is given" do
        it "raises an exception" do
          expect { subject.validate_pushes!(pushes) }
            .to raise_error(Vagrant::Errors::PushStrategyNotProvided)
        end
      end

      context "when --all is given" do
        it "returns the pushes" do
          expect(subject.validate_pushes!(pushes, [], all: true))
            .to eq([:noop, :ftp])
        end
      end
    end
  end
end
