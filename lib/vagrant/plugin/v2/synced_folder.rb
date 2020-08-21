module Vagrant
  module Plugin
    module V2
      # This is the base class for a synced folder implementation.
      class SyncedFolder
        class Collection < Hash

          # @return [Array<Symbol>] names of synced folder types
          def types
            keys
          end

          # Fetch the synced plugin folder of the given type
          #
          # @param [Symbol] t Synced folder type
          # @return [Vagrant::Plugin::V2::SyncedFolder]
          def type(t)
            f = detect { |k, _| k.to_sym == t.to_sym }.last
            raise KeyError, "Unknown synced folder type" if !f
            f.values.first[:plugin]
          end

          # Converts to a regular Hash and removes
          # plugin instances so the result is ready
          # for serialization
          #
          # @return [Hash]
          def to_h
            c = lambda do |h|
              h.keys.each do |k|
                if h[k].is_a?(Hash)
                  h[k] = c.call(h[k].to_h.clone)
                end
              end
              h
            end
            h = c.call(super)
            h.values.each do |f|
              f.values.each do |g|
                g.delete(:plugin)
              end
            end
            h
          end
        end

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

        def _initialize(machine, synced_folder_type)
          plugins = Vagrant.plugin("2").manager.synced_folders
          capabilities = Vagrant.plugin("2").manager.synced_folder_capabilities
          initialize_capabilities!(synced_folder_type, plugins, capabilities, machine)
          self
        end
      end
    end
  end
end
