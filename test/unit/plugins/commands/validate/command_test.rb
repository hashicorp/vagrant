require_relative "../../../base"
require_relative "../../../../../plugins/commands/validate/command"

describe VagrantPlugins::CommandValidate::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) do
    isolated_environment
  end

  let(:env) do
    iso_env.create_vagrant_env
  end

  let(:argv)   { [] }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/commands/port/locales/en.yml")
    I18n.reload!
  end

  subject { described_class.new(argv, env) }

  describe "#execute" do
    it "validates correct Vagrantfile" do
      iso_env.vagrantfile(<<-EOH)
        Vagrant.configure("2") do |config|
          config.vm.box = "hashicorp/precise64"
        end
      EOH

      expect(env.ui).to receive(:info).with { |message, _|
        expect(message).to include("Vagrantfile validated successfully.")
      }

      expect(subject.execute).to eq(0)
    end

    it "validates the configuration" do
      iso_env.vagrantfile <<-EOH
        Vagrant.configure("2") do |config|
          config.vm.bix = "hashicorp/precise64"
        end
      EOH

      expect { subject.execute }.to raise_error(Vagrant::Errors::ConfigInvalid) { |err|
        expect(err.message).to include("The following settings shouldn't exist: bix")
      }
    end
  end
end
