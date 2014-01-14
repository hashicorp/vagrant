require "log4r"
require 'optparse'

require "listen"

require "vagrant/action/builtin/mixin_synced_folders"

require_relative "../helper"

module VagrantPlugins
  module SyncedFolderRSync
    module Command
      class RsyncAuto < Vagrant.plugin("2", :command)
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def self.synopsis
          "syncs rsync synced folders automatically when files change"
        end

        def execute
          @logger = Log4r::Logger.new("vagrant::commands::rsync-auto")

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant rsync-auto [vm-name]"
            o.separator ""
          end

          # Parse the options and return if we don't have any target.
          argv = parse_options(opts)
          return if !argv

          # Build up the paths that we need to listen to.
          paths = {}
          with_target_vms(argv) do |machine|
            folders = synced_folders(machine)[:rsync]
            next if !folders || folders.empty?

            folders.each do |id, folder_opts|
              hostpath = folder_opts[:hostpath]
              hostpath = File.expand_path(hostpath, machine.env.root_path)
              paths[hostpath] ||= []
              paths[hostpath] << {
                machine: machine,
                opts:    folder_opts,
              }
            end
          end

          @logger.info("Listening to paths: #{paths.keys.sort.inspect}")
          @logger.info("Listening via: #{Listen::Adapter.select.inspect}")
          callback = method(:callback).to_proc.curry[paths]
          listener = Listen.to(*paths.keys, &callback)
          listener.start
          listener.thread.join

          0
        end

        # This is the callback that is called when any changes happen
        def callback(paths, modified, added, removed)
          @logger.debug("File change callback called!")
          @logger.debug("  - Modified: #{modified.inspect}")
          @logger.debug("  - Added: #{added.inspect}")
          @logger.debug("  - Removed: #{removed.inspect}")

          tosync = []
          paths.each do |hostpath, folders|
            # Find out if this path should be synced
            found = catch(:done) do
              [modified, added, removed].each do |changed|
                changed.each do |listenpath|
                  throw :done, true if listenpath.start_with?(hostpath)
                end
              end

              # Make sure to return false if all else fails so that we
              # don't sync to this machine.
              false
            end

            # If it should be synced, store it for later
            tosync << folders if found
          end

          # Sync all the folders that need to be synced
          tosync.each do |folders|
            folders.each do |opts|
              ssh_info = opts[:machine].ssh_info
              RsyncHelper.rsync_single(opts[:machine], ssh_info, opts[:opts])
            end
          end
        end
      end
    end
  end
end
