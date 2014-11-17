require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/local-exec/config")

describe VagrantPlugins::LocalExecPush::Config do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/local-exec/locales/en.yml")
    I18n.reload!
  end

  let(:machine) { double("machine") }

  describe "#script" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.script).to be(nil)
    end
  end

  describe "#inline" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.inline).to be(nil)
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))
      subject.finalize!
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["Local Exec push"] }

    context "when script is present" do
      before { subject.script = "foo.sh" }

      context "when inline is present" do
        before { subject.inline = "echo" }

        it "returns an error" do
          expect(errors).to include(
            I18n.t("local_exec_push.errors.cannot_specify_script_and_inline")
          )
        end
      end

      context "when inline is not present" do
        before { subject.inline = "" }

        it "does not return an error" do
          expect(errors).to be_empty
        end
      end
    end

    context "when script is not present" do
      before { subject.script = "" }

      context "when inline is present" do
        before { subject.inline = "echo" }

        it "does not return an error" do
          expect(errors).to be_empty
        end
      end

      context "when inline is not present" do
        before { subject.inline = "" }

        it "returns an error" do
          expect(errors).to include(I18n.t("local_exec_push.errors.missing_attribute",
            attribute: "script",
          ))
        end
      end
    end
  end
end
