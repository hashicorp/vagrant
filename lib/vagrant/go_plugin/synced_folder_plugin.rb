require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Contains all synced folder functionality for go-plugin
    module SyncedFolderPlugin

      # Helper class used to provide a wrapper around a go-plugin
      # synced folder so that it can be interacted with normally
      # within Vagrant
      class SyncedFolder < Vagrant.plugin("2", :synced_folder)
        include GRPCPlugin

        # Cleanup synced folders
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] opts Folder options
        def cleanup(machine, opts)
          plugin_client.cleanup(
            Vagrant::Proto::SyncedFolders.new(
              machine: JSON.dump(machine),
              options: JSON.dump(opts),
              folders: JSON.dump({})))
          nil
        end

        # Disable synced folders
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def disable(machine, folders, opts)
          plugin_client.disable(
            Vagrant::Proto::SyncedFolders.new(
              machine: JSON.dump(machine),
              folders: JSON.dump(folders),
              options: JSON.dump(opts)))
          nil
        end

        # Enable synced folders
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def enable(machine, folders, opts)
          plugin_client.enable(
            Vagrant::Proto::SyncedFolders.new(
              machine: JSON.dump(machine),
              folders: JSON.dump(folders),
              options: JSON.dump(options)))
          nil
        end

        # Prepare synced folders
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def prepare(machine, folders, opts)
          plugin_client.prepare(
            Vagrant::Proto::SyncedFolders.new(
              machine: JSON.dump(machine),
              folders: JSON.dump(folders),
              options: JSON.dump(options)))
          nil
        end

        # Check if plugin is usable
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @return [Boolean]
        def usable?(machine, raise_error=false)
          plugin_client.is_usable(
            Vagrant::Proto::Machine.new(
              machine: JSON.dump(machine))).result
        end

        # @return [String]
        def name
          if !@_name
            @_name = plugin_client.name(Vagrant::Proto::Empty.new).name
          end
          @_name
        end
      end
    end
  end
end
