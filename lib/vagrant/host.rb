require "vagrant/capability_host"

module Vagrant
  # This class handles host-OS specific interations. It is responsible for
  # detecting the proper host OS implementation and delegating capabilities
  # to plugins.
  #
  # See {Guest} for more information on capabilities.
  class Host
    include CapabilityHost

    def initialize(host, hosts, capabilities, env)
      initialize_capabilities!(host, hosts, capabilities, env)
    end
  end
end
