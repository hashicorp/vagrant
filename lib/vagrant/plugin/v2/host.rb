module Vagrant
  module Plugin
    module V2
      # Base class for a host in Vagrant. A host class contains functionality
      # that is specific to a specific OS that is running Vagrant. This
      # abstraction is done becauase there is some host-specific logic that
      # Vagrant must do in some cases.
      class Host
        # This returns true/false depending on if the current running system
        # matches the host class.
        #
        # @return [Boolean]
        def detect?(env)
          false
        end
      end
    end
  end
end
