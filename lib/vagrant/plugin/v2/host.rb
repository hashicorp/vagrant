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
              # `hosts` might not have the key, if the entry does not exist within
              # the Ruby runtime. For example, if a Ruby plugin has a dependency
              # on a Go plugin.
              if hosts.has_key?(entry.last)
                entry = hosts[entry.last]
                n = entry.last
              end
            end
          end
          ancestors
        end
      end
    end
  end
end
