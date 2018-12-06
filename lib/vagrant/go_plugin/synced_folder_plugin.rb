require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Contains all synced folder functionality for go-plugin
    module SyncedFolderPlugin

      # Helper class used to provide a wrapper around a go-plugin
      # synced folder so that it can be interacted with normally
      # within Vagrant
      class SyncedFolder < Vagrant.plugin("2", :synced_folder)
        include DirectGoPlugin

        # Cleanup synced folders
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] opts Folder options
        def cleanup(machine, opts)
          SyncedFolderPlugin.interface.cleanup(plugin_name, machine, opts)
        end

        # Disable synced folders
        #
        # @param [String] plugin_name Name of plugin
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def disable(machine, folder, opts)
          SyncedFolderPlugin.interface.disable(plugin_name, machine, folder, opts)
        end

        # Enable synced folders
        #
        # @param [String] plugin_name Name of plugin
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def enable(machine, folder, opts)
          SyncedFolderPlugin.interface.enable(plugin_name, machine, folder, opts)
        end

        # Check if plugin is usable
        #
        # @param [Vagrant::Machine] machine Vagrant guest
        # @return [Boolean]
        def usable?(machine, raise_error=false)
          SyncedFolderPlugin.interface.usable?(plugin_name, machine)
        end
      end

      # @return [Interface]
      def self.interface
        unless @_interface
          @_interface = Interface.new
        end
        @_interface
      end

      # Synced folder interface to go-plugin
      class Interface
        include GoPlugin::Core

        typedef :string, :folders
        typedef :string, :folder_options

        # synced folder plugin functions
        attach_function :_cleanup, :SyncedFolderCleanup,
          [:plugin_name, :vagrant_machine, :folder_options], :plugin_result
        attach_function :_disable, :SyncedFolderDisable,
          [:plugin_name, :vagrant_machine, :folders, :folder_options], :plugin_result
        attach_function :_enable, :SyncedFolderEnable,
          [:plugin_name, :vagrant_machine, :folders, :folder_options], :plugin_result
        attach_function :_list_synced_folders, :ListSyncedFolders,
          [], :plugin_result
        attach_function :_usable, :SyncedFolderIsUsable,
          [:plugin_name, :vagrant_machine], :plugin_result

        # Cleanup synced folders
        #
        # @param [String] plugin_name Name of plugin
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] opts Folder options
        def cleanup(plugin_name, machine, opts)
          load_result {
            _cleanup(plugin_name, dump_machine(machine), JSON.dump(opts))
          }
        end

        # Disable synced folders
        #
        # @param [String] plugin_name Name of plugin
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def disable(plugin_name, machine, folders, opts)
          load_result {
            _disable(plugin_name, dump_machine(machine),
              JSON.dump(folders), JSON.dump(opts))
          }
        end

        # Enable synced folders
        #
        # @param [String] plugin_name Name of plugin
        # @param [Vagrant::Machine] machine Vagrant guest
        # @param [Hash] folders Folders to enable
        # @param [Hash] opts Folder options
        def enable(plugin_name, machine, folders, opts)
          load_result {
            _enable(plugin_name, dump_machine(machine),
              JSON.dump(folders), JSON.dump(opts))
          }
        end

        # List of available synced folder plugins
        #
        # @return [Array]
        def list_synced_folders
          load_result { _list_synced_folders }
        end

        # Check if plugin is usable
        #
        # @param [String] plugin_name Name of plugin
        # @param [Vagrant::Machine] machine Vagrant guest
        # @return [Boolean]
        def usable?(plugin_name, machine)
          load_result {
            _usable(plugin_name, dump_machine(machine))
          }
        end

        # Load any detected synced folder plugins
        def load!
          if !@loaded
            @loaded = true
            logger.debug("synced folder go-plugins have not been loaded... loading")
            list_synced_folders.each do |f_name, f_details|
              logger.debug("loading go-plugin synced folder #{f_name}. details - #{f_details}")
              # Create new synced folder class wrapper
              folder_klass = Class.new(SyncedFolder)
              folder_klass.go_plugin_name = f_name
              # Create new plugin to register the synced folder
              plugin_klass = Class.new(Vagrant.plugin("2"))
              # Define the plugin
              plugin_klass.class_eval do
                name "#{f_name} Synced Folder"
                description f_details[:description]
              end
              # Register the synced folder
              plugin_klass.synced_folder(f_name.to_sym, f_details.fetch(:priority, 10)) do
                folder_klass
              end
              # Register any guest capabilities
              CapabilityPlugin.interface.generate_guest_capabilities(f_name, :synced_folder, plugin_klass)
              # Register any host capabilities
              CapabilityPlugin.interface.generate_host_capabilities(f_name, :synced_folder, plugin_klass)
              # Register any provider capabilities
              CapabilityPlugin.interface.generate_provider_capabilities(f_name, :synced_folder, plugin_klass)
              logger.debug("completed loading synced folder go-plugin #{f_name}")
              logger.info("loaded go-plugin synced folder - #{f_name}")
            end
          else
            logger.warn("synced folder go-plugins have already been loaded. ignoring load request.")
          end
        end
      end
    end
  end
end
