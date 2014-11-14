require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/local-exec/config")

describe VagrantPlugins::LocalExecPush::Config do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/local-exec/locales/en.yml")
    I18n.reload!
  end

  let(:machine) { double("machine") }

  describe "#command" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.command).to be(nil)
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))

      subject.command = "echo"
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["Local Exec push"] }

    context "when the command is missing" do
      it "returns an error" do
        subject.command = ""
        subject.finalize!
        expect(errors).to include(I18n.t("local_exec_push.errors.missing_attribute",
          attribute: "command",
        ))
      end
    end
  end
end
