require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/atlas/config")

describe VagrantPlugins::AtlasPush::Config do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/atlas/locales/en.yml")
    I18n.reload!
  end

  let(:machine) { double("machine") }

  around(:each) do |example|
    with_temp_env("ATLAS_TOKEN" => nil) do
      example.run
    end
  end

  before do
    subject.token = "foo"
  end

  describe "#address" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.address).to be(nil)
    end
  end

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

  describe "#vcs" do
    it "defaults to true" do
      subject.finalize!
      expect(subject.vcs).to be(true)
    end
  end

  describe "#uploader_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.uploader_path).to be(nil)
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
          data_dir:  Pathname.new(""),
        ))

      subject.app           = "sethvargo/bacon"
      subject.dir           = "."
      subject.vcs           = true
      subject.uploader_path = "uploader"
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["Atlas push"] }

    context "when the token is missing" do
      context "when a vagrant-login token exists" do
        before do
          allow(subject).to receive(:token_from_vagrant_login)
            .and_return("token_from_vagrant_login")
        end

        it "uses the token from vagrant-login" do
          subject.token = ""
          subject.finalize!
          expect(errors).to be_empty
          expect(subject.token).to eq("token_from_vagrant_login")
        end
      end

      context "when a token is given in the Vagrantfile" do
        before do
          allow(subject).to receive(:token_from_vagrant_login)
            .and_return("token_from_vagrant_login")
        end

        it "uses the token in the Vagrantfile" do
          subject.token = "token_from_vagrantfile"
          subject.finalize!
          expect(errors).to be_empty
          expect(subject.token).to eq("token_from_vagrantfile")
        end
      end

      context "when a token is in the environment" do
        it "uses the token in the Vagrantfile" do
          with_temp_env("ATLAS_TOKEN" => "foo") do
            subject.finalize!
          end

          expect(errors).to be_empty
          expect(subject.token).to eq("foo")
        end
      end

      context "when no token is given" do
        before do
          allow(subject).to receive(:token_from_vagrant_login)
            .and_return(nil)
        end

        it "returns an error" do
          subject.token = ""
          subject.finalize!
          expect(errors).to include(I18n.t("atlas_push.errors.missing_token"))
        end
      end
    end

    context "when the app is missing" do
      it "returns an error" do
        subject.app = ""
        subject.finalize!
        expect(errors).to include(I18n.t("atlas_push.errors.missing_attribute",
          attribute: "app",
        ))
      end
    end

    context "when the dir is missing" do
      it "returns an error" do
        subject.dir = ""
        subject.finalize!
        expect(errors).to include(I18n.t("atlas_push.errors.missing_attribute",
          attribute: "dir",
        ))
      end
    end

    context "when the vcs is missing" do
      it "does not return an error" do
        subject.vcs = ""
        subject.finalize!
        expect(errors).to be_empty
      end
    end

    context "when the uploader_path is missing" do
      it "returns an error" do
        subject.uploader_path = ""
        subject.finalize!
        expect(errors).to be_empty
      end
    end
  end

  describe "#merge" do
    context "when includes are given" do
      let(:one) { described_class.new }
      let(:two) { described_class.new }

      it "merges the result" do
        one.includes = %w(a b c)
        two.includes = %w(c d e)
        result = one.merge(two)
        expect(result.includes).to eq(%w(a b c d e))
      end
    end

    context "when excludes are given" do
      let(:one) { described_class.new }
      let(:two) { described_class.new }

      it "merges the result" do
        one.excludes = %w(a b c)
        two.excludes = %w(c d e)
        result = one.merge(two)
        expect(result.excludes).to eq(%w(a b c d e))
      end
    end
  end

  describe "#include" do
    it "adds the item to the list" do
      subject.include("me")
      expect(subject.includes).to include("me")
    end
  end

  describe "#exclude" do
    it "adds the item to the list" do
      subject.exclude("not me")
      expect(subject.excludes).to include("not me")
    end
  end
end
