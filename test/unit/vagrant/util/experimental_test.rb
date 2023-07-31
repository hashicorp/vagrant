# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/experimental"

describe Vagrant::Util::Experimental do
  include_context "unit"
  before(:all) { described_class.reset! }
  after(:each) { described_class.reset! }
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

  describe "#global_enabled?" do
    it "returns true if enabled with '1'" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("1")
      expect(subject.global_enabled?).to eq(true)
    end

    it "returns false if enabled with a partial list of features" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("list,of,features")
      expect(subject.global_enabled?).to eq(false)
    end

    it "returns false if disabled" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("0")
      expect(subject.global_enabled?).to eq(false)
    end

    it "returns false if not set" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return(nil)
      expect(subject.global_enabled?).to eq(false)
    end
  end

  describe "#feature_enabled?" do
    it "returns true if flag set to 1" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("1")
      expect(subject.feature_enabled?("anything")).to eq(true)
    end

    it "returns true if flag contains feature requested" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature")
      expect(subject.feature_enabled?("secret_feature")).to eq(true)
    end

    it "returns true if flag contains feature requested and the request is a symbol" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature")
      expect(subject.feature_enabled?(:secret_feature)).to eq(true)
    end

    it "returns true if flag contains feature requested with other features 'enabled'" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature,other_secret")
      expect(subject.feature_enabled?("secret_feature")).to eq(true)
    end

    it "returns false if flag is set but does not contain feature requested" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("fake_feature")
      expect(subject.feature_enabled?("secret_feature")).to eq(false)
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

  describe "#features_requested" do
    it "returns an array of requested features" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature,other_secret")
      expect(subject.features_requested).to eq(["secret_feature","other_secret"])
    end
  end

  describe "#guard_with" do
    it "does not execute the block if the feature is not requested" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return(nil)
      expect{|b| subject.guard_with("secret_feature", &b) }.not_to yield_control
    end

    it "executes the block if the feature is valid and requested" do
      allow(ENV).to receive(:[]).with("VAGRANT_EXPERIMENTAL").and_return("secret_feature,other_secret")
      expect{|b| subject.guard_with("secret_feature", &b) }.to yield_control
    end
  end
end
