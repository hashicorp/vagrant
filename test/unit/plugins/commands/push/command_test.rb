require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/push/command")

describe VagrantPlugins::CommandPush::Command do
  include_context "unit"
  include_context "command plugin helpers"

  def create_registry(items={})
    Vagrant::Registry.new.tap do |registry|
      items.each do |k,v|
        registry.register(k) { v }
      end
    end
  end

  let(:env) do
    isolated_environment.tap do |env|
      env.vagrantfile("")
      env.create_vagrant_env
    end
  end

  let(:argv)   { [] }
  let(:pushes) { create_registry }

  subject { described_class.new(argv, env) }

  before do
    Vagrant.plugin("2").manager.stub(pushes: pushes)
  end

  describe "#execute" do
    before do
      allow(subject).to receive(:validate_pushes!)
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
  end

  describe "#validate_pushes!" do
    context "when there are no pushes defined" do
      let(:pushes) { create_registry }

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
      let(:pushes) { create_registry(noop: noop) }

      context "when a strategy is given" do
        context "when that strategy is not defined" do
          it "raises an exception" do
            expect { subject.validate_pushes!(pushes, :bacon) }
              .to raise_error(Vagrant::Errors::PushStrategyNotDefined)
          end
        end

        context "when that strategy is defined" do
          it "does not raise an exception" do
            expect { subject.validate_pushes!(pushes, :noop) }
              .to_not raise_error
          end
        end
      end

      context "when no strategy is given" do
        it "does not raise an exception" do
          expect { subject.validate_pushes!(pushes) }
            .to_not raise_error
        end
      end
    end

    context "when there are multiple pushes defined" do
      let(:noop) { double("noop") }
      let(:ftp)  { double("ftp") }
      let(:pushes) { create_registry(noop: noop, ftp: ftp) }

      context "when a strategy is given" do
        context "when that strategy is not defined" do
          it "raises an exception" do
            expect { subject.validate_pushes!(pushes, :bacon) }
              .to raise_error(Vagrant::Errors::PushStrategyNotDefined)
          end
        end

        context "when that strategy is defined" do
          it "does not raise an exception" do
            expect { subject.validate_pushes!(pushes, :noop) }
              .to_not raise_error
            expect { subject.validate_pushes!(pushes, :ftp) }
              .to_not raise_error
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
