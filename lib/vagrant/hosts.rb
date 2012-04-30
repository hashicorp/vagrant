require 'log4r'

module Vagrant
  module Hosts
    # This method detects the correct host based on the `match?` methods
    # implemented in the registered hosts.
    #
    # @param [Hash] registry Hash mapping key to host class
    def self.detect(registry)
      logger = Log4r::Logger.new("vagrant::hosts")

      # Sort the hosts by their precedence
      host_klasses = registry.values.sort_by { |a| a.precedence }.reverse
      logger.debug("Host path search classes: #{host_klasses.inspect}")

      # Test for matches and return the host class that matches
      host_klasses.each do |klass|
        if klass.match?
          logger.info("Host class: #{klass}")
          return klass
        end
      end

      # No matches found...
      return nil
    end

    # Interface for classes which house behavior that is specific
    # to the host OS that is running Vagrant.
    #
    # By default, Vagrant will attempt to choose the best option
    # for your machine, but the host may also be explicitly set
    # via the `config.vagrant.host` parameter.
    class Base
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
