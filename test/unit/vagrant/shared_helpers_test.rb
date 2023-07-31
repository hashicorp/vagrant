# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../base", __FILE__)

require "vagrant/shared_helpers"
require "vagrant/util/platform"

describe Vagrant do
  include_context "unit"

  subject { described_class }

  describe ".global_lock" do
    it "yields to the block" do
      result = subject.global_lock { 42 }
      expect(result).to eq(42)
    end
  end

  describe ".in_installer?" do
    it "is not if env is not set" do
      with_temp_env("VAGRANT_INSTALLER_ENV" => nil) do
        expect(subject.in_installer?).to be(false)
      end
    end

    it "is if env is set" do
      with_temp_env("VAGRANT_INSTALLER_ENV" => "/foo") do
        expect(subject.in_installer?).to be(true)
      end
    end
  end

  describe ".installer_embedded_dir" do
    it "returns nil if not in an installer" do
      allow(Vagrant).to receive(:in_installer?).and_return(false)
      expect(subject.installer_embedded_dir).to be_nil
    end

    it "returns the set directory" do
      allow(Vagrant).to receive(:in_installer?).and_return(true)

      with_temp_env("VAGRANT_INSTALLER_EMBEDDED_DIR" => "/foo") do
        expect(subject.installer_embedded_dir).to eq("/foo")
      end
    end
  end

  describe ".plugins_enabled?" do
    it "returns true if the env is not set" do
      with_temp_env("VAGRANT_NO_PLUGINS" => nil) do
        expect(subject.plugins_enabled?).to be(true)
      end
    end

    it "returns false if the env is set" do
      with_temp_env("VAGRANT_NO_PLUGINS" => "1") do
        expect(subject.plugins_enabled?).to be(false)
      end
    end
  end

  describe ".server_url" do
    it "defaults to the default value" do
      with_temp_env("VAGRANT_SERVER_URL" => nil) do
        expect(subject.server_url).to eq(
          Vagrant::DEFAULT_SERVER_URL)
      end
    end

    it "defaults if the string is empty" do
      with_temp_env("VAGRANT_SERVER_URL" => "") do
        expect(subject.server_url).to eq(
          Vagrant::DEFAULT_SERVER_URL)
      end
    end

    it "is the VAGRANT_SERVER_URL value" do
      with_temp_env("VAGRANT_SERVER_URL" => "foo") do
        expect(subject.server_url).to eq("foo")
      end
    end

    it "is the VAGRANT_SERVER_URL value if the server url is configured" do
      with_temp_env("VAGRANT_SERVER_URL" => "foo") do
        expect(subject.server_url('bar')).to eq("foo")
      end
    end

    it "is the configured server url if VAGRANT_SERVER_URL is not set" do
      with_temp_env("VAGRANT_SERVER_URL" => nil) do
        expect(subject.server_url("bar")).to eq("bar")
      end
    end
  end

  describe ".user_data_path" do
    around do |example|
      env = {
        "USERPROFILE" => nil,
        "VAGRANT_HOME" => nil,
      }
      with_temp_env(env) { example.run }
    end

    it "defaults to ~/.vagrant.d" do
      expect(subject.user_data_path).to eql(Pathname.new("~/.vagrant.d").expand_path)
    end

    it "is VAGRANT_HOME if set" do
      with_temp_env("VAGRANT_HOME" => "/foo") do
        expected = Pathname.new("/foo").expand_path
        expect(subject.user_data_path).to eql(expected)
      end
    end

    it "is USERPROFILE/.vagrant.d if set" do
      with_temp_env("USERPROFILE" => "/bar") do
        expected = Pathname.new("/bar/.vagrant.d").expand_path
        expect(subject.user_data_path).to eql(expected)
      end
    end

    it "prefers VAGRANT_HOME over USERPROFILE if both are set" do
      env = {
        "USERPROFILE" => "/bar",
        "VAGRANT_HOME" => "/foo",
      }

      with_temp_env(env) do
        expected = Pathname.new("/foo").expand_path
        expect(subject.user_data_path).to eql(expected)
      end
    end
  end

  describe ".prerelease?" do
    it "should return true when Vagrant version is development" do
      stub_const("Vagrant::VERSION", "1.0.0.dev")
      expect(subject.prerelease?).to be(true)
    end

    it "should return false when Vagrant version is release" do
      stub_const("Vagrant::VERSION", "1.0.0")
      expect(subject.prerelease?).to be(false)
    end
  end

  describe ".allow_prerelease_dependencies?" do
    context "with environment variable set" do
      before { allow(ENV).to receive(:[]).with("VAGRANT_ALLOW_PRERELEASE").and_return("1") }

      it "should return true" do
        expect(subject.allow_prerelease_dependencies?).to be(true)
      end
    end

    context "with environment variable unset" do
      before { allow(ENV).to receive(:[]).with("VAGRANT_ALLOW_PRERELEASE").and_return(nil) }

      it "should return false" do
        expect(subject.allow_prerelease_dependencies?).to be(false)
      end
    end
  end

  describe ".enable_resolv_replace" do
    it "should not attempt to require resolv-replace by default" do
      expect(subject).not_to receive(:require).with("resolv-replace")
      subject.enable_resolv_replace
    end

    it "should require resolv-replace when VAGRANT_ENABLE_RESOLV_REPLACE is set" do
      expect(subject).to receive(:require).with("resolv-replace")
      with_temp_env("VAGRANT_ENABLE_RESOLV_REPLACE" => "1"){ subject.enable_resolv_replace }
    end

    it "should not require resolv-replace when VAGRANT_DISABLE_RESOLV_REPLACE is set" do
      expect(subject).not_to receive(:require).with("resolv-replace")
      with_temp_env("VAGRANT_ENABLE_RESOLV_REPLACE" => "1", "VAGRANT_DISABLE_RESOLV_REPLACE" => "1") do
        subject.enable_resolv_replace
      end
    end
  end

  describe ".global_logger" do
    after{ subject.global_logger = nil }

    it "should return a logger when none have been provided" do
      expect(subject.global_logger).not_to be_nil
    end

    it "should return previously set logger" do
      logger = double("logger")
      expect(subject.global_logger = logger).to eq(logger)
      expect(subject.global_logger).to eq(logger)
    end
  end

  describe ".add_default_cli_options" do
    it "should raise a type error when no provided with proc" do
      expect { subject.add_default_cli_options(true) }.
        to raise_error(TypeError)
    end

    it "should raise an argument error when proc does not accept argument" do
      expect { subject.add_default_cli_options(proc{}) }.
        to raise_error(ArgumentError)
    end

    it "should accept a proc type argument" do
      expect(subject.add_default_cli_options(proc{|o|})).to be_nil
    end
  end

  describe ".default_cli_options" do
    it "should return array of items" do
      expect(subject.default_cli_options).to be_a(Array)
    end
  end
end
