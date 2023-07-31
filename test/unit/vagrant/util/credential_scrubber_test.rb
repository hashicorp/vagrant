# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/credential_scrubber"

describe Vagrant::Util::CredentialScrubber do
  subject{ Vagrant::Util::CredentialScrubber }

  after{ subject.reset! }

  describe ".url_scrubber" do
    let(:user){ "vagrant-user" }
    let(:password){ "vagrant-pass" }
    let(:url){ "http://#{user}:#{password}@example.com" }

    it "should remove user credentials from URL" do
      result = subject.url_scrubber(url)
      expect(result).not_to include(user)
      expect(result).not_to include(password)
    end
  end

  describe ".sensitive" do
    it "should return a nil value" do
      expect(subject.sensitive("value")).to be_nil
    end

    it "should add value to list of strings" do
      subject.sensitive("value")
      expect(subject.sensitive_strings).to include("value")
    end

    it "should remove duplicates" do
      subject.sensitive("value")
      subject.sensitive("value")
      expect(subject.sensitive_strings.count("value")).to eq(1)
    end

    it "should not add an empty string" do
      subject.sensitive("")
      expect(subject.sensitive_strings).to be_empty
    end

    it "should type cast input to string" do
      subject.sensitive(2)
      expect(subject.sensitive_strings.first).to eq("2")
    end
  end

  describe ".unsensitive" do
    it "should return a nil value" do
      expect(subject.unsensitive("value")).to be_nil
    end

    it "should remove value from list" do
      subject.sensitive("value")
      expect(subject.sensitive_strings).to include("value")
      subject.unsensitive("value")
      expect(subject.sensitive_strings).not_to include("value")
    end
  end

  describe ".sensitive_strings" do
    it "should always return the same array" do
      expect(subject.sensitive_strings).to be(subject.sensitive_strings)
    end
  end

  describe ".desensitize" do
    let(:to_scrub){ [] }
    let(:string){ "a line of text with my-birthday and my-cats-birthday embedded" }
    before{ to_scrub.each{|s| subject.sensitive(s) }}

    context "with no sensitive strings registered" do
      it "should not modify the string" do
        expect(subject.desensitize(string)).to eq(string)
      end
    end

    context "with single value registered" do
      let(:to_scrub){ ["my-birthday"] }

      it "should remove the registered value" do
        expect(subject.desensitize(string)).not_to include(to_scrub.first)
      end
    end

    context "with multiple values registered" do
      let(:to_scrub){ ["my-birthday", "my-cats-birthday"] }

      it "should remove all registered values" do
        result = subject.desensitize(string)
        to_scrub.each do |registered_value|
          expect(result).not_to include(registered_value)
        end
      end
    end

    context "with sensitive words that are part of non-sensitive words" do
      let(:to_scrub){ ["a"] }
     
      it "should not remove parts of words" do
        result = subject.desensitize(string)
        to_scrub.each do |registered_value|
          expect(result).not_to match(/(\W|^)#{registered_value}(\W|$)/)
        end
        expect(result).to include("my-birthday")
        expect(result).to include("my-cats-birthday")
      end
    end

    context "with sensitive words that are part of non-sensitive words" do
      let(:to_scrub){ ["avery@strange/string^indeed!"] }
      let(:string){ "a line of text with avery@strange/string^indeed! my-birthday and my-cats-birthday embedded" }

      it "should work for strings with escape characters" do
        result = subject.desensitize(string)
        to_scrub.each do |registered_value|
          expect(result).not_to include(registered_value)
        end
      end
    end
  end
end
