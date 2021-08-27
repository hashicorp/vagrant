module Vagrant
  module Plugin
    module V2
      # A base class for a guest OS. A guest OS is responsible for detecting
      # that the guest operating system running within the machine. The guest
      # can then be extended with various "guest capabilities" which are their
      # own form of plugin.
      #
      # The guest class itself is only responsible for detecting itself,
      # and may provide helpers for the capabilities.
      class Guest
        # This method is called when the machine is booted and has communication
        # capabilities in order to detect whether this guest operating system
        # is running within the machine.
        #
        # @return [Boolean]
        def detect?(machine)
          false
        end

        # Returns list of parents for
        # this guest
        #
        # @return [Array<Symbol>]
        def parents
          guests = Vagrant.plugin("2").manager.guests.to_hash
          ancestors = []
          n, entry = guests.detect { |_, v| v.first == self.class }
          while n
            n = nil
            if entry.last
              ancestors << entry.last
              entry = guests[entry.last]
              n = entry.last
            end
          end
          ancestors
        end
      end
    end
  end
end
