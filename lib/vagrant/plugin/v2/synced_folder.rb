module Vagrant
  module Plugin
    module V2
      # This is the base class for a synced folder implementation.
      class SyncedFolder
        include CapabilityHost

        # This is called early when the synced folder is set to determine
        # if this implementation can be used for this machine. This should
        # return true or false.
        #
        # @param [Machine] machine
        # @param [Boolean] raise_error If true, should raise an exception
        #   if it isn't usable.
        # @return [Boolean]
        def usable?(machine, raise_error=false)
        end

        # DEPRECATED: This will be removed.
        #
        # @deprecated
        def prepare(machine, folders, opts)
        end

        # This is called after the machine is booted and after networks
        # are setup.
        #
        # This might be called with new folders while the machine is running.
        # If so, then this should add only those folders without removing
        # any existing ones.
        #
        # No return value.
        def enable(machine, folders, opts)
        end

        # This is called to remove the synced folders from a running
        # machine.
        #
        # This is not guaranteed to be called, but this should be implemented
        # by every synced folder implementation.
        #
        # @param [Machine] machine The machine to modify.
        # @param [Hash] folders The folders to remove. This will not contain
        #   any folders that should remain.
        # @param [Hash] opts Any options for the synced folders.
        def disable(machine, folders, opts)
        end

        # This is called after destroying the machine during a
        # `vagrant destroy` and also prior to syncing folders during
        # a `vagrant up`.
        #
        # No return value.
        #
        # @param [Machine] machine
        # @param [Hash] opts
        def cleanup(machine, opts)
        end

        def _initialize(machine)
          synced_folder_type = default_synced_folder_type(machine, Vagrant.plugin("2").manager.synced_folders)
          plugins = Vagrant.plugin("2").manager.synced_folders
          capabilities = Vagrant.plugin("2").manager.synced_folder_capabilities
          initialize_capabilities!(synced_folder_type, plugins, capabilities, machine)
        end
    
        # This goes over all the registered synced folder types and returns
        # the highest priority implementation that is usable for this machine.
        def default_synced_folder_type(machine, plugins)
          ordered = []
    
          # First turn the plugins into an array
          plugins.each do |key, data|
            impl     = data[0]
            priority = data[1]
    
            ordered << [priority, key, impl]
          end
    
          # Order the plugins by priority. Higher is tried before lower.
          ordered = ordered.sort { |a, b| b[0] <=> a[0] }
    
          allowed_types = machine.config.vm.allowed_synced_folder_types
          if allowed_types
            ordered = allowed_types.map do |type|
              ordered.find do |_, key, impl|
                key == type
              end
            end.compact
          end
    
          # Find the proper implementation
          ordered.each do |_, key, impl|
            return key if impl.new.usable?(machine)
          end
    
          return nil
        end
      end
    end
  end
end
