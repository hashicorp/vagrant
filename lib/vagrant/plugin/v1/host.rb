module Vagrant
  module Plugin
    module V1
      # Base class for a host in Vagrant. A host class contains functionality
      # that is specific to a specific OS that is running Vagrant. This
      # abstraction is done becauase there is some host-specific logic that
      # Vagrant must do in some cases.
      class Host
        # This returns true/false depending on if the current running system
        # matches the host class.
        #
        # @return [Boolean]
        def self.match?
          nil
        end

        # The precedence of the host when checking for matches. This is to
        # allow certain host such as generic OS's ("Linux", "BSD", etc.)
        # to be specified last.
        #
        # The hosts with the higher numbers will be checked first.
        #
        # If you're implementing a basic host, you can probably ignore this.
        def self.precedence
          5
        end

        # Initializes a new host class.
        #
        # The only required parameter is a UI object so that the host
        # objects have some way to communicate with the outside world.
        #
        # @param [UI] ui UI for the hosts to output to.
        def initialize(ui)
          @ui = ui
        end

        # Returns true of false denoting whether or not this host supports
        # NFS shared folder setup. This method ideally should verify that
        # NFS is installed.
        #
        # @return [Boolean]
        def nfs?
          false
        end

        # Exports the given hash of folders via NFS.
        #
        # @param [String] id A unique ID that is guaranteed to be unique to
        #   match these sets of folders.
        # @param [String] ip IP of the guest machine.
        # @param [Hash] folders Shared folders to sync.
        def nfs_export(id, ip, folders)
        end

        # Prunes any NFS exports made by Vagrant which aren't in the set
        # of valid ids given.
        #
        # @param [Array<String>] valid_ids Valid IDs that should not be
        #   pruned.
        def nfs_prune(valid_ids)
        end
      end
    end
  end
end
