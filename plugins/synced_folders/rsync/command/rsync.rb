require 'optparse'

require "vagrant/action/builtin/mixin_synced_folders"

require_relative "../helper"

module VagrantPlugins
  module SyncedFolderRSync
    module Command
      class Rsync < Vagrant.plugin("2", :command)
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def self.synopsis
          "syncs rsync synced folders to remote machine"
        end

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant rsync [vm-name]"
            o.separator ""
          end

          # Parse the options and return if we don't have any target.
          argv = parse_options(opts)
          return if !argv

          # Go through each machine and perform the rsync
          error = false
          with_target_vms(argv) do |machine|
            if !machine.communicate.ready?
              machine.ui.error(I18n.t("vagrant.rsync_communicator_not_ready"))
              error = true
              next
            end

            # Determine the rsync synced folders for this machine
            folders = synced_folders(machine)[:rsync]
            next if !folders || folders.empty?

            # Get the SSH info for this machine so we can access it
            communicator_info = machine.communicator_info

            # Sync them!
            folders.each do |id, folder_opts|
              RsyncHelper.rsync_single(machine, communicator_info, folder_opts)
            end
          end

          return error ? 1 : 0
        end
      end
    end
  end
end
