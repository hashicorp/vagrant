require File.expand_path("../../base", __FILE__)

require "vagrant/shared_helpers"
require "vagrant/util/platform"

describe Vagrant do
  include_context "unit"

  subject { described_class }

  describe "#in_installer?" do
    it "is not if env is not set" do
      with_temp_env("VAGRANT_INSTALLER_ENV" => nil) do
        expect(subject.in_installer?).to be_false
      end
    end

    it "is if env is set" do
      with_temp_env("VAGRANT_INSTALLER_ENV" => "/foo") do
        expect(subject.in_installer?).to be_true
      end
    end
  end

  describe "#installer_embedded_dir" do
    it "returns nil if not in an installer" do
      Vagrant.stub(in_installer?: false)
      expect(subject.installer_embedded_dir).to be_nil
    end

    it "returns the set directory" do
      Vagrant.stub(in_installer?: true)

      with_temp_env("VAGRANT_INSTALLER_EMBEDDED_DIR" => "/foo") do
        expect(subject.installer_embedded_dir).to eq("/foo")
      end
    end
  end

  describe "#plugins_enabled?" do
    it "returns true if the env is not set" do
      with_temp_env("VAGRANT_NO_PLUGINS" => nil) do
        expect(subject.plugins_enabled?).to be_true
      end
    end

    it "returns false if the env is set" do
      with_temp_env("VAGRANT_NO_PLUGINS" => "1") do
        expect(subject.plugins_enabled?).to be_false
      end
    end
  end

  describe "#server_url" do
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
  end

  describe "#user_data_path" do
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

    it "prefers VAGRANT_HOME over USERPOFILE if both are set" do
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
end
