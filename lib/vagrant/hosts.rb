require 'log4r'

module Vagrant
  module Hosts
    autoload :Base,    'vagrant/hosts/base'
    autoload :Arch,    'vagrant/hosts/arch'
    autoload :BSD,     'vagrant/hosts/bsd'
    autoload :FreeBSD, 'vagrant/hosts/freebsd'
    autoload :Fedora,  'vagrant/hosts/fedora'
    autoload :Gentoo,  'vagrant/hosts/gentoo'
    autoload :Linux,   'vagrant/hosts/linux'
    autoload :Windows, 'vagrant/hosts/windows'

    # This method detects the correct host based on the `match?` methods
    # implemented in the registered hosts.
    def self.detect(registry)
      logger = Log4r::Logger.new("vagrant::hosts")

      # Sort the hosts by their precedence
      host_klasses = registry.to_hash.values
      host_klasses = host_klasses.sort_by { |a| a.precedence }.reverse
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
