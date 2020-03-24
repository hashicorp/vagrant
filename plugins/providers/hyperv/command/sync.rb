require 'optparse'

require "vagrant/action/builtin/mixin_synced_folders"

require_relative "../sync_helper"

module VagrantPlugins
  module HyperV
    module Command
      class Sync < Vagrant.plugin("2", :command)
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def self.synopsis
          "syncs synced folders to remote machine"
        end

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant sync [vm-name]"
            o.separator ""
            o.separator "This command forces any synced folders to sync."
            o.separator "Hyper-V currently does not provider an automatic sync so a manual command is used."
            o.separator ""
          end

          # Parse the options and return if we don't have any target.
          argv = parse_options(opts)
          return if !argv

          # Go through each machine and perform the rsync
          error = false
          with_target_vms(argv) do |machine|
            if !machine.communicate.ready?
              machine.ui.error(I18n.t("vagrant_hyperv.sync.communicator_not_ready"))
              error = true
              next
            end

            # Determine the rsync synced folders for this machine
            folders = synced_folders(machine, cached: true)[:hyperv]
            next if !folders || folders.empty?

            # short guestpaths first, so we don't step on ourselves
            folders = folders.sort_by do |id, data|
              if data[:guestpath]
                data[:guestpath].length
              else
                # A long enough path to just do this at the end.
                10000
              end
            end

            # Calculate the owner and group
            ssh_info = machine.ssh_info

            # Sync them!
            folders.each do |id, data|
              next unless data[:guestpath]

              SyncHelper.sync_single machine, ssh_info, data
            end
          end

          return error ? 1 : 0
        end
      end
    end
  end
end
