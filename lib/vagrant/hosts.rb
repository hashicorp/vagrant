module Vagrant
  module Hosts
    autoload :Base,  'vagrant/hosts/base'
    autoload :Arch,  'vagrant/hosts/arch'
    autoload :BSD,   'vagrant/hosts/bsd'
    autoload :FreeBSD,'vagrant/hosts/freebsd'
    autoload :Fedora, 'vagrant/hosts/fedora'
    autoload :Linux, 'vagrant/hosts/linux'

    # This method detects the correct host based on the `match?` methods
    # implemented in the registered hosts.
    def self.detect(registry)
      # Sort the hosts by their precedence
      host_klasses = registry.to_hash.values
      host_klasses = host_klasses.sort_by { |a| a.precedence }.reverse

      # Test for matches and return the host class that matches
      host_klasses.each do |klass|
        return klass if klass.match?
      end

      # No matches found...
      return nil
    end
  end
end
