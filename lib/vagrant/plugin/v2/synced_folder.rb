module Vagrant
  module Plugin
    module V2
      # This is the base class for a synced folder implementation.
      class SyncedFolder
        # This is called early when the synced folder is set to determine
        # if this implementation can be used for this machine. This should
        # return true or false.
        #
        # @return [Boolean]
        def usable?(machine)
        end

        # This is called before the machine is booted, allowing the
        # implementation to make any machine modifications or perhaps
        # verifications.
        #
        # No return value.
        def prepare(machine, folders, opts)
        end

        # This is called after the machine is booted and after networks
        # are setup.
        #
        # No return value.
        def enable(machine, folders, opts)
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
