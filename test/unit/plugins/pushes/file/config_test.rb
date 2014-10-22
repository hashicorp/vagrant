require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/file/config")

describe VagrantPlugins::FileDeploy::Config do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#validate" do
    it "returns an error if destination is not specified" do
      subject.finalize!

      result = subject.validate(machine)

      expect(result["File push"]).to eql([
        I18n.t("vagrant.pushes.file.no_destination")
      ])
    end

    it "returns no errors when the config is valid" do
      existing_file = File.expand_path(__FILE__)

      subject.destination = existing_file
      subject.finalize!

      result = subject.validate(machine)

      expect(result["File push"]).to be_empty
    end
  end
end
