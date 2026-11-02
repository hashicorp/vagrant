# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/void/cap/nfs"
require_relative "../../../../../../lib/vagrant/util"

describe VagrantPlugins::HostVoid::Cap::NFS do

  include_context "unit"

  let(:caps) do
    VagrantPlugins::HostVoid::Plugin
      .components
      .host_capabilities[:void]
  end

  let(:env) { double("env") }

  context ".nfs_check_command" do
    it "should provide nfs_check_command capability" do
      expect(caps.get(:nfs_check_command)).to eq(described_class)
    end

    it "should return command to execute" do
      expect(caps.get(:nfs_check_command).nfs_check_command(env)).to be_a(String)
    end
  end

  context ".nfs_start_command" do
    it "should provide nfs_start_command capability" do
      expect(caps.get(:nfs_start_command)).to eq(described_class)
    end

    it "should return command to execute" do
      expect(caps.get(:nfs_start_command).nfs_start_command(env)).to be_a(String)
    end
  end

  context ".nfs_installed" do
    let(:exit_code) { 0 }
    let(:result) { Vagrant::Util::Subprocess::Result.new(exit_code, "", "") }

    before { allow(Vagrant::Util::Subprocess).to receive(:execute).
        with("/usr/bin/xbps-query", "nfs-utils").and_return(result) }

    it "should provide nfs_installed capability" do
      expect(caps.get(:nfs_installed)).to eq(described_class)
    end

    context "when installed" do
      it "should return true" do
        expect(caps.get(:nfs_installed).nfs_installed(env)).to be_truthy
      end
    end

    context "when not installed" do
      let(:exit_code) { 1 }

      it "should return false" do
        expect(caps.get(:nfs_installed).nfs_installed(env)).to be_falsey
      end
    end
  end
end
