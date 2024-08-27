# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/bsd/cap/nfs"

describe VagrantPlugins::HostBSD::Cap::NFS do

  include_context "unit"

  describe ".nfs_export" do
    let(:environment) { double("environment", host: host) }
    let(:host) { double("host") }
    let(:ui) { Vagrant::UI::Silent.new }
    let(:id) { "UUID" }
    let(:ips) { [] }
    let(:folders) { {} }

    before do
      allow(host).to receive(:capability).and_return("")
      allow(Vagrant::Util::TemplateRenderer).to receive(:render).and_return("")
      allow(described_class).to receive(:sleep)
      allow(described_class).to receive(:nfs_cleanup)
      allow(described_class).to receive(:system)
      allow(described_class).to receive(:nfs_running?).and_return(true)
      allow(File).to receive(:writable?).with("/etc/exports")

      allow(Vagrant::Util::Subprocess).to receive(:execute).with("nfsd", "checkexports").
        and_return(Vagrant::Util::Subprocess::Result.new(0, "", ""))
    end

    it "should execute successfully when no folders are defined" do
      expect { described_class.nfs_export(environment, ui, id, ips, folders) }.
        not_to raise_error
    end

    context "with single folder defined" do
      let(:folders) {
        {"/vagrant" => {
          type: :nfs, guestpath: "/vagrant", hostpath: "/Users/vagrant/paths", disabled: false}}
      }

      it "should execute successfully" do
        expect { described_class.nfs_export(environment, ui, id, ips, folders) }.
          not_to raise_error
      end

      it "should resolve the host path" do
        expect(host).to receive(:capability).with(:resolve_host_path, folders["/vagrant"][:hostpath]).and_return("")
        described_class.nfs_export(environment, ui, id, ips, folders)
      end
    end

    context "when nfsd is not running" do 
      before {
        allow(described_class).to receive(:nfs_running?).and_return(false)
      }
      it "should restart nfsd" do
        expect(host).to receive(:capability).with(:nfs_restart_command).and_return(["restart"])
        expect(described_class).to receive(:system).with("restart")
        described_class.nfs_export(environment, ui, id, ips, folders)
      end
    end

    context "when nfsd is running" do 
      before {
        allow(described_class).to receive(:nfs_running?).and_return(true)
      }
      it "should update nfsd" do
        expect(host).to receive(:capability).with(:nfs_update_command).and_return(["update"])
        expect(described_class).to receive(:system).with("update")
        described_class.nfs_export(environment, ui, id, ips, folders)
      end
    end
  end
end
