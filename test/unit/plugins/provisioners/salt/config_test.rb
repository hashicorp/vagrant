require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/salt/config")

describe VagrantPlugins::Salt::Config do
  include_context "unit"

  subject { described_class.new }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  describe "validate" do
    let(:error_key) { "salt provisioner" }

    it "passes by default" do
      subject.finalize!
      result = subject.validate(machine)
      expect(result[error_key]).to be_empty
    end

    context "minion_config" do
      it "fails if minion_config is set and missing" do
        subject.minion_config = "/nope/nope/i/dont/exist"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end

      it "is valid if is set and not missing" do
        subject.minion_config = File.expand_path(__FILE__)
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end
    end

    context "master_config" do
      it "fails if master_config is set and missing" do
        subject.master_config = "/ceci/nest/pas/une/path"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end

      it "is valid if is set and not missing" do
        subject.master_config = File.expand_path(__FILE__)
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end
    end

    context "grains_config" do
      it "fails if grains_config is set and missing" do
        subject.grains_config = "/nope/still/not/here"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end

      it "is valid if is set and not missing" do
        subject.grains_config = File.expand_path(__FILE__)
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end
    end

    context "salt_call_args" do
      it "fails if salt_call_args is not an array" do
        subject.salt_call_args = "--flags"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end

      it "is valid if is set and not missing" do
        subject.salt_call_args = ["--flags"]
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end
    end

    context "salt_args" do
      it "fails if not an array" do
        subject.salt_args = "--flags"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end

      it "is valid if is set and not missing" do
        subject.salt_args = ["--flags"]
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end
    end

    context "python_version" do
      it "is valid if is set and not missing" do
        subject.python_version = "2"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end

      it "can be a string" do
        subject.python_version = "2"
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end

      it "can be an integer" do
        subject.python_version = 2
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to be_empty
      end

      it "is not a number that is not an integer" do
        subject.python_version = 2.7
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end

      it "is not a string that does not parse to an integer" do
        subject.python_version = '2.7'
        subject.finalize!

        result = subject.validate(machine)
        expect(result[error_key]).to_not be_empty
      end
    end
  end
end
