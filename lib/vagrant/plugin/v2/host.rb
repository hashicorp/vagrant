module Vagrant
  module Plugin
    module V2
      # Base class for a host in Vagrant. A host class contains functionality
      # that is specific to a specific OS that is running Vagrant. This
      # abstraction is done because there is some host-specific logic that
      # Vagrant must do in some cases.
      class Host
        # This returns true/false depending on if the current running system
        # matches the host class.
        #
        # @return [Boolean]
        def detect?(env)
          false
        end

        # Returns list of parents for
        # this host
        #
        # @return [Array<Symbol>]
        def parents
          hosts = Vagrant.plugin("2").manager.hosts.to_hash
          ancestors = []
          n, entry = hosts.detect { |_, v| v.first == self.class }
          while n
            n = nil
            if entry.last
              ancestors << entry.last
              entry = hosts[entry.last]
              n = entry.last
            end
          end
          ancestors
        end
      end
    end
  end
end
