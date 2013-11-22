module Vagrant
  module Plugin
    module V2
      # This is the base class for a synced folder implementation.
      class SyncedFolder
        def usable?(machine)
        end

        def prepare(machine, folders)
        end

        def enable(machine, folders)
        end
      end
    end
  end
end
