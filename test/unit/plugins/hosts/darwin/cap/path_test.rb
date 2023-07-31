# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/darwin/cap/path"
require_relative "../../../../../../plugins/hosts/darwin/cap/version"

describe VagrantPlugins::HostDarwin::Cap::Path do
  include_context "unit"

  let(:caps) do
    VagrantPlugins::HostDarwin::Plugin
      .components
      .host_capabilities[:darwin]
  end

  let(:host) { @host }
  let(:hosts) {
    {
      darwin: [VagrantPlugins::HostDarwin::Host, :bsd]
    }
  }

  let(:env) do
    ienv = isolated_environment
    ienv.vagrantfile("")
    env = ienv.create_vagrant_env
    @host = Vagrant::Host.new(
      :darwin,
      hosts,
      {darwin: caps},
      env
    )
    env.instance_variable_set(:@host, @host)
    env
  end

  describe ".resolve_host_path" do
    let(:cap) { caps.get(:resolve_host_path) }
    let(:path) { "/test/vagrant/path" }
    let(:firmlink_map) { {} }
    let(:macos_version) { Gem::Version.new("10.15.1") }
    let(:result) {
      Vagrant::Util::Subprocess::Result.new(0, macos_version, "")
    }

    before do
      # allow(env).to receive(:host).
      #   and_return(host)
      # allow(host).to receive(:capability).
      #   with(:version).
      #   and_return(macos_version)
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        with("sw_vers", "-productVersion").
        and_return(result)
      allow(described_class).to receive(:firmlink_map).
        and_return(firmlink_map)
    end

    it "should not change the path when no firmlinks are defined" do
      expect(cap.resolve_host_path(env, path)).to eq(path)
    end

    context "when firmlink map contains non-matching values" do
      let(:firmlink_map) { {"/users" => "users", "/system" => "system"} }

      it "should not change the path" do
        expect(cap.resolve_host_path(env, path)).to eq(path)
      end
    end

    context "when firmlink map contains matching value" do
      let(:firmlink_map) { {"/users" => "users", "/test" => "test"} }

      it "should update the path" do
        expect(cap.resolve_host_path(env, path)).not_to eq(path)
      end

      it "should prefix the path with the defined data path" do
        expect(cap.resolve_host_path(env, path)).to start_with(described_class.const_get(:FIRMLINK_DATA_PATH))
      end
    end

    context "when firmlink map match points to different named target" do
      let(:firmlink_map) { {"/users" => "users", "/test" => "other"} }

      it "should update the path" do
        expect(cap.resolve_host_path(env, path)).not_to eq(path)
      end

      it "should prefix the path with the defined data path" do
        expect(cap.resolve_host_path(env, path)).
          to start_with(described_class.const_get(:FIRMLINK_DATA_PATH))
      end

      it "should include the updated path name" do
        expect(cap.resolve_host_path(env, path)).to include("other")
      end
    end

    context "when macos version is later than catalina" do
      let(:macos_version) { Gem::Version.new("10.16.1") }

      it "should not update the path" do
        expect(cap.resolve_host_path(env, path)).to eq(path)
      end

      it "should not prefix the path with the defined data path" do
        expect(cap.resolve_host_path(env, path)).
          not_to start_with(described_class.const_get(:FIRMLINK_DATA_PATH))
      end
    end
  end

  describe ".firmlink_map" do
    let(:cap) { caps.get(:firmlink_map) }
    before { described_class.reset! }

    context "when firmlink definition file does not exist" do
      before { expect(File).to receive(:exist?).
          with(described_class.const_get(:FIRMLINK_DEFS)).and_return(false) }

      it "should return an empty hash" do
        expect(described_class.firmlink_map).to eq({})
      end
    end

    context "when firmlink definition file exists with values" do
      before do
        expect(File).to receive(:exist?).with(described_class.const_get(:FIRMLINK_DEFS)).and_return(true)
        expect(File).to receive(:readlines).with.(described_class.const_get(:FIRMLINK_DEFS)).
          and_return(["/System\tSystem\n", "/Users\tUsers\n", "/Library/Something\tLibrary/Somethingelse"])

        it "should generate a non-empty hash" do
          expect(described_class.firmlink_map).not_to be_empty
        end

        it "should properly create entries" do
          result = described_class.firmlink_map
          expect(result["/System"]).to eq("System")
          expect(result["/Users"]).to eq("Users")
          expect(result["/Library/Something"]).to eq("Library/Somethingelse")
        end

        it "should only load values once" do
          describe_class.firmlink_app
          expect(File).not_to receive(:readlines)
          describe_class.firmlink_app
        end
      end
    end
  end
end
