require File.expand_path("../../../base", __FILE__)

require "vagrant/util/experimental"

describe Vagrant::Util::Experimental do
  include_context "unit"
  before(:each) { described_class.reset! }
  subject { described_class }

  describe "#enabled?" do
    it "returns true if enabled with '1'" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("1")
      expect(subject.enabled?).to eq(true)
    end

    it "returns true if enabled with a list of features" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("list,of,features")
      expect(subject.enabled?).to eq(true)
    end

    it "returns false if disabled" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("0")
      expect(subject.enabled?).to eq(false)
    end

    it "returns false if not set" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return(nil)
      expect(subject.enabled?).to eq(false)
    end
  end

  describe "#feature_enabled?" do
    before(:each) do
      stub_const("Vagrant::Util::Experimental::VALID_FEATURES", ["secret_feature"])
    end

    it "returns true if flag set to 1" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("1")
      expect(subject.feature_enabled?("anything")).to eq(true)
    end

    it "returns true if flag contains feature requested" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature")
      expect(subject.feature_enabled?("secret_feature")).to eq(true)
    end

    it "returns true if flag contains feature requested with other features 'enabled'" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature,other_secret")
      expect(subject.feature_enabled?("secret_feature")).to eq(true)
    end

    it "returns false if flag does not contain feature requested" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature")
      expect(subject.feature_enabled?("anything")).to eq(false)
    end

    it "returns false if flag set to 0" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("0")
      expect(subject.feature_enabled?("anything")).to eq(false)
    end

    it "returns false if flag is not set" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return(nil)
      expect(subject.feature_enabled?("anything")).to eq(false)
    end
  end
end
