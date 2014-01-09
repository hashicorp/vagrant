require "log4r"

require "vagrant/capability_host"

module Vagrant
  # This class handles guest-OS specific interactions with a machine.
  # It is primarily responsible for detecting the proper guest OS
  # implementation and then delegating capabilities.
  #
  # Vagrant has many tasks which require specific guest OS knowledge.
  # These are implemented using a guest/capability system. Various plugins
  # register as "guests" which determine the underlying OS of the system.
  # Then, "guest capabilities" register themselves for a specific OS (one
  # or more), and these capabilities are called.
  #
  # Example capabilities might be "mount_virtualbox_shared_folder" or
  # "configure_networks".
  #
  # This system allows for maximum flexibility and pluginability for doing
  # guest OS specific operations.
  class Guest
    include CapabilityHost

    def initialize(machine, guests, capabilities)
      @logger       = Log4r::Logger.new("vagrant::guest")
      @capabilities = capabilities
      @guests       = guests
      @machine      = machine
    end

    # This will detect the proper guest OS for the machine and set up
    # the class to actually execute capabilities.
    def detect!
      @logger.info("Detect guest for machine: #{@machine}")

      guest_name = @machine.config.vm.guest
      initialize_capabilities!(guest_name, @guests, @capabilities, @machine)
    end

    # This returns whether the guest is ready to work. If this returns
    # `false`, then {#detect!} should be called in order to detect the
    # guest OS.
    #
    # @return [Boolean]
    def ready?
      !!capability_host_chain
    end

    # Returns the specified or detected guest type name
    #
    # @return [Symbol]
    def name
      capability_host_chain[0][0]
    end
  end
end
