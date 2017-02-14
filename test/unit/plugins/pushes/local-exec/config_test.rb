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

  describe "#args" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.args).to be(nil)
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

        it "passes with string args" do
          subject.args = "a string"
          expect(errors).to be_empty
        end

        it "passes with integer args" do
          subject.args = 1
          expect(errors).to be_empty
        end

        it "passes with array args" do
          subject.args = ["an", "array"]
          expect(errors).to be_empty
        end

        it "returns an error if args is neither a string nor an array" do
          neither_array_nor_string = Object.new

          subject.args = neither_array_nor_string
          expect(errors).to include(
            I18n.t("local_exec_push.errors.args_bad_type")
          )
        end

        it "handles scalar array args" do
          subject.args = ["string", 1, 2]
          expect(errors).to be_empty
        end

        it "returns an error if args is an array with non-scalar types" do
          subject.args = [[1]]
          expect(errors).to include(
            I18n.t("local_exec_push.errors.args_bad_type")
          )
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

        it "passes with string args" do
          subject.args = "a string"
          expect(errors).to be_empty
        end

        it "passes with integer args" do
          subject.args = 1
          expect(errors).to be_empty
        end

        it "passes with array args" do
          subject.args = ["an", "array"]
          expect(errors).to be_empty
        end

        it "returns an error if args is neither a string nor an array" do
          neither_array_nor_string = Object.new

          subject.args = neither_array_nor_string
          expect(errors).to include(
            I18n.t("local_exec_push.errors.args_bad_type")
          )
        end

        it "handles scalar array args" do
          subject.args = ["string", 1, 2]
          expect(errors).to be_empty
        end

        it "returns an error if args is an array with non-scalar types" do
          subject.args = [[1]]
          expect(errors).to include(
            I18n.t("local_exec_push.errors.args_bad_type")
          )
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
