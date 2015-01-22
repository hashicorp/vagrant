require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/heroku/config")

describe VagrantPlugins::HerokuPush::Config do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/heroku/locales/en.yml")
    I18n.reload!
  end

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#app" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.app).to be(nil)
    end
  end

  describe "#dir" do
    it "defaults to ." do
      subject.finalize!
      expect(subject.dir).to eq(".")
    end
  end

  describe "#git_bin" do
    it "defaults to git" do
      subject.finalize!
      expect(subject.git_bin).to eq("git")
    end
  end

  describe "#remote" do
    it "defaults to git" do
      subject.finalize!
      expect(subject.remote).to eq("heroku")
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))

      subject.app = "bacon"
      subject.dir = "."
      subject.git_bin = "git"
      subject.remote = "heroku"
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["Heroku push"] }

    context "when the app is missing" do
      it "does not return an error" do
        subject.app = ""
        subject.finalize!
        expect(errors).to be_empty
      end
    end

    context "when the git_bin is missing" do
      it "returns an error" do
        subject.git_bin = ""
        subject.finalize!
        expect(errors).to include(I18n.t("heroku_push.errors.missing_attribute",
          attribute: "git_bin",
        ))
      end
    end

    context "when the remote is missing" do
      it "returns an error" do
        subject.remote = ""
        subject.finalize!
        expect(errors).to include(I18n.t("heroku_push.errors.missing_attribute",
          attribute: "remote",
        ))
      end
    end

    context "when the dir is missing" do
      it "returns an error" do
        subject.dir = ""
        subject.finalize!
        expect(errors).to include(I18n.t("heroku_push.errors.missing_attribute",
          attribute: "dir",
        ))
      end
    end
  end
end
