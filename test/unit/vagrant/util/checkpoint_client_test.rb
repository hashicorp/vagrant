# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/checkpoint_client"

describe Vagrant::Util::CheckpointClient do
  include_context "unit"

  let(:iso_env) { isolated_environment }
  let(:env)     { iso_env.create_vagrant_env }
  let(:result) { {} }

  subject{ Vagrant::Util::CheckpointClient.instance }

  after{ subject.reset! }

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  it "should not be enabled by default" do
    expect(subject.enabled).to be(false)
  end

  describe "#setup" do
    let(:environment){ {} }
    before{ with_temp_env(environment){ subject.setup(env) } }

    it "should enable after setup" do
      expect(subject.enabled).to be(true)
    end

    it "should generate required paths" do
      expect(subject.files).not_to be_empty
    end

    context "with VAGRANT_CHECKPOINT_DISABLE set" do
      let(:environment){ {"VAGRANT_CHECKPOINT_DISABLE" => "1"} }

      it "should not be enabled after setup" do
        expect(subject.enabled).to be(false)
      end
    end
  end

  describe "#check" do
    context "without #setup" do
      it "should not start the check" do
        expect(Thread).not_to receive(:new)
        subject.check
      end
    end

    context "with setup" do
      before{ subject.setup(env) }

      it "should start the check" do
        expect(Thread).to receive(:new)
        subject.check
      end

      it "should call checkpoint" do
        expect(Thread).to receive(:new).and_yield
        expect(Checkpoint).to receive(:check)
        subject.check
      end
    end
  end

  describe "#display" do
    it "should only display once" do
      expect(subject).to receive(:version_check).once
      expect(subject).to receive(:alerts_check).once

      2.times{ subject.display }
    end

    it "should not display cached information" do
      expect(subject).to receive(:result).and_return("cached" => true).at_least(:once)
      expect(subject).not_to receive(:version_check)
      expect(subject).not_to receive(:alerts_check)

      subject.display
    end
  end

  describe "#alerts_check" do
    let(:critical){
      [{"level" => "critical", "message" => "critical message",
        "url" => "http://example.com", "date" => Time.now.to_i}]
    }
    let(:warn){
      [{"level" => "warn", "message" => "warn message",
        "url" => "http://example.com", "date" => Time.now.to_i}]
    }
    let(:info){
      [{"level" => "info", "message" => "info message",
        "url" => "http://example.com", "date" => Time.now.to_i}]
    }

    before{ subject.setup(env) }

    context "with no alerts" do
      it "should not display alerts" do
        expect(env.ui).not_to receive(:info)
        subject.alerts_check
      end
    end

    context "with critical alerts" do
      let(:result) { {"alerts" => critical} }

      it "should display critical alert" do
        expect(env.ui).to receive(:error)
        subject.alerts_check
      end
    end

    context "with warn alerts" do
      let(:result) { {"alerts" => warn} }

      it "should display warn alerts" do
        expect(env.ui).to receive(:warn)
        subject.alerts_check
      end
    end

    context "with info alerts" do
      let(:result) { {"alerts" => info} }

      it "should display info alerts" do
        expect(env.ui).to receive(:info).at_least(:once)
        subject.alerts_check
      end
    end

    context "with mixed alerts" do
      let(:result) { {"alerts" => info + warn + critical} }

      it "should display all alert types" do
        expect(env.ui).to receive(:info).at_least(:once)
        expect(env.ui).to receive(:warn).at_least(:once)
        expect(env.ui).to receive(:error).at_least(:once)

        subject.alerts_check
      end
    end
  end

  describe "#version_check" do
    before{ subject.setup(env) }

    let(:new_version){ Gem::Version.new(Vagrant::VERSION).bump.to_s }
    let(:old_version){ Gem::Version.new("1.0.0") }

    context "latest version is same as current version" do
      let(:result) { {"current_version" => Vagrant::VERSION } }

      it "should not display upgrade information" do
        expect(env.ui).not_to receive(:info)
        subject.version_check
      end
    end

    context "latest version is older than current version" do
      let(:result) { {"current_version" => old_version} }

      it "should not display upgrade information" do
        expect(env.ui).not_to receive(:info)
        subject.version_check
      end
    end

    context "latest version is newer than current version" do
      let(:result) { {"current_version" => new_version} }

      it "should display upgrade information" do
        expect(env.ui).to receive(:info).at_least(:once)
        subject.version_check
      end

      it "should display upgrade information on error channel" do
        expect(env.ui).to receive(:info).with(any_args, hash_including(channel: :error)).at_least(:once)
        subject.version_check
      end
    end
  end
end
