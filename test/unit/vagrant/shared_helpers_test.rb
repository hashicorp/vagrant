require File.expand_path("../../base", __FILE__)

require "vagrant/shared_helpers"
require "vagrant/util/platform"

describe Vagrant do
  include_context "unit"

  subject { described_class }

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
