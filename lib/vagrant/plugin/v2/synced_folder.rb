module Vagrant
  module Plugin
    module V2
      # This is the base class for a synced folder implementation.
      class SyncedFolder
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
      end
    end
  end
end
