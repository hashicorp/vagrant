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
  end
end
