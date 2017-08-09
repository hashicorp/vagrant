require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/push/command")

describe VagrantPlugins::CommandPush::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) { isolated_environment }
  let(:env) do
    iso_env.vagrantfile(<<-VF)
      Vagrant.configure("2") do |config|
        config.vm.box = "hashicorp/precise64"
      end
    VF
    iso_env.create_vagrant_env
  end

  let(:argv)   { [] }
  let(:pushes) { {} }

  subject { described_class.new(argv, env) }

  before do
    allow(Vagrant.plugin("2").manager).to receive(:pushes).and_return(pushes)
  end

  describe "#execute" do
    before do
      allow(subject).to receive(:validate_pushes!)
        .and_return(:noop)
      allow(env).to receive(:pushes)
      allow(env).to receive(:push)
    end

    it "validates the pushes" do
      expect(subject).to receive(:validate_pushes!).once
      subject.execute
    end

    it "delegates to Environment#push" do
      expect(env).to receive(:push).once
      subject.execute
    end

    it "validates the configuration" do
      iso_env.vagrantfile <<-EOH
        Vagrant.configure("2") do |config|
          config.vm.box = "hashicorp/precise64"

          config.push.define "noop" do |push|
            push.bad = "ham"
          end
        end
      EOH

      subject = described_class.new(argv, iso_env.create_vagrant_env)
      allow(subject).to receive(:validate_pushes!)
        .and_return(:noop)

      expect { subject.execute }.to raise_error(Vagrant::Errors::ConfigInvalid) { |err|
        expect(err.message).to include("The following settings shouldn't exist: bad")
      }
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
            expect(subject.validate_pushes!(pushes, :noop)).to eq(:noop)
          end
        end
      end

      context "when no strategy is given" do
        it "returns the strategy" do
          expect(subject.validate_pushes!(pushes)).to eq(:noop)
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
            expect(subject.validate_pushes!(pushes, :noop)).to eq(:noop)
            expect(subject.validate_pushes!(pushes, :ftp)).to eq(:ftp)
          end
        end
      end

      context "when no strategy is given" do
        it "raises an exception" do
          expect { subject.validate_pushes!(pushes) }
            .to raise_error(Vagrant::Errors::PushStrategyNotProvided)
        end
      end
    end
  end
end
