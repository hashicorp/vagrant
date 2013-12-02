module Vagrant
  module Plugin
    module V2
      # This is the base class for a synced folder implementation.
      class SyncedFolder
        def usable?(machine)
        end

        def prepare(machine, folders, opts)
        end

        def enable(machine, folders, opts)
        end

        def cleanup(machine)
        end
      end
    end
  end
end
