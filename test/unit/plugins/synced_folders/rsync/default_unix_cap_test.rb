# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require Vagrant.source_root.join("plugins/synced_folders/rsync/default_unix_cap")

describe VagrantPlugins::SyncedFolderRSync::DefaultUnixCap do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:subject) { Class.new { extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap } }

  describe "#rsync_installed" do
    it "tests if rsync is on the path" do
      expect(machine.communicate).to receive(:test).with("which rsync").
        and_return(true)

      subject.rsync_installed(machine)
    end
  end


  describe "#rsync_command" do
    it "returns the rsync command" do
      expect( subject.rsync_command(machine) ).to eq("sudo rsync")
    end
  end

  describe "#rsync_post" do
    let(:opts) {{:type=>:rsync,
                 :guestpath=>"/vagrant",
                 :hostpath=>"/home/user/syncfolder",
                 :disabled=>false,
                 :__vagrantfile=>true,
                 :exclude=>[".vagrant"],
                 :owner=>"vagrant",
                 :group=>"vagrant"}}

    let(:cmd) { "find /vagrant -path /vagrant/.vagrant -prune -o '!' -type l -a '(' ! -user vagrant -or ! -group vagrant ')' -exec chown vagrant:vagrant '{}' +" }

    it "executes the rsync post command" do
      expect(machine.communicate).to receive(:sudo).
        with(cmd)
      subject.rsync_post(machine, opts)
    end
  end

  describe "#build_rsync_chown" do
    let(:opts) {{:type=>:rsync,
                 :guestpath=>"/vagrant",
                 :hostpath=>"/home/user/syncfolder",
                 :disabled=>false,
                 :__vagrantfile=>true,
                 :exclude=>[".vagrant"],
                 :owner=>"vagrant",
                 :group=>"vagrant"}}

    let(:cmd) { "find /vagrant -path /vagrant/.vagrant -prune -o '!' -type l -a '(' ! -user vagrant -or ! -group vagrant ')' -exec chown vagrant:vagrant '{}' +" }
    let(:no_exclude_cmd) { "find /vagrant '!' -type l -a '(' ! -user vagrant -or ! -group vagrant ')' -exec chown vagrant:vagrant '{}' +" }

    let(:empty_opts) {{:type=>:rsync,
                 :guestpath=>"/vagrant",
                 :hostpath=>"/home/user/syncfolder",
                 :disabled=>false,
                 :__vagrantfile=>true,
                 :exclude=>[],
                 :owner=>"vagrant",
                 :group=>"vagrant"}}

    it "builds up a command to properly chown folders" do
      command = subject.build_rsync_chown(opts)
      expect(command).to eq(cmd)
    end

    it "does not include any excludes if the array is empty" do
      command = subject.build_rsync_chown(empty_opts)
      expect(command).to eq(no_exclude_cmd)
    end
  end
end
