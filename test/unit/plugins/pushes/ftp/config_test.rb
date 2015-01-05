require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/ftp/config")

describe VagrantPlugins::FTPPush::Config do
  include_context "unit"

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/pushes/ftp/locales/en.yml")
    I18n.reload!
  end

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#host" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.host).to be(nil)
    end
  end

  describe "#username" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.username).to be(nil)
    end
  end

  describe "#password" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.password).to be(nil)
    end
  end

  describe "#passive" do
    it "defaults to true" do
      subject.finalize!
      expect(subject.passive).to be(true)
    end
  end

  describe "#secure" do
    it "defaults to false" do
      subject.finalize!
      expect(subject.secure).to be(false)
    end
  end

  describe "#destination" do
    it "defaults to /" do
      subject.finalize!
      expect(subject.destination).to eq("/")
    end
  end

  describe "#dir" do
    it "defaults to ." do
      subject.finalize!
      expect(subject.dir).to eq(".")
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

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))

      subject.host        = "ftp.example.com"
      subject.username    = "sethvargo"
      subject.password    = "bacon"
      subject.destination = "/"
      subject.dir         = "."
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["FTP push"] }

    context "when the host is missing" do
      it "returns an error" do
        subject.host = ""
        subject.finalize!
        expect(errors).to include(I18n.t("ftp_push.errors.missing_attribute",
          attribute: "host",
        ))
      end
    end

    context "when the username is missing" do
      it "returns an error" do
        subject.username = ""
        subject.finalize!
        expect(errors).to include(I18n.t("ftp_push.errors.missing_attribute",
          attribute: "username",
        ))
      end
    end

    context "when the password is missing" do
      it "does not return an error" do
        subject.password = ""
        subject.finalize!
        expect(errors).to be_empty
      end
    end

    context "when the destination is missing" do
      it "returns an error" do
        subject.destination = ""
        subject.finalize!
        expect(errors).to include(I18n.t("ftp_push.errors.missing_attribute",
          attribute: "destination",
        ))
      end
    end

    context "when the dir is missing" do
      it "returns an error" do
        subject.dir = ""
        subject.finalize!
        expect(errors).to include(I18n.t("ftp_push.errors.missing_attribute",
          attribute: "dir",
        ))
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
