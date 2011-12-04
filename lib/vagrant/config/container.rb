module Vagrant
  module Config
    # Contains loaded configuration values and provides access to those
    # values.
    #
    # This is the class returned when loading configuration and stores
    # the completely loaded configuration values. This class is meant to
    # be immutable.
    class Container
      # Initializes the configuration container.
      #
      # A `Vagrant::Config::top` should be passed in to initialize this.
      # The container will use this top in order to separate and provide
      # access to the configuration.
      def initialize(top)
        @top = top
      end

      # This returns the global configuration values. These are values
      # that apply to the system as a whole, and not to a specific virtual
      # machine or so on. Examples of this sort of configuration: the
      # class of the host system, name of the Vagrant dotfile, etc.
      def global
        # For now, we just return all the configuration, until we
        # separate out global vs. non-global configuration keys.
        @top
      end

      # This returns the configuration for a specific virtual machine.
      # The values for this configuration are usually pertinent to a
      # single virtual machine and do not affect the system globally.
      def for_vm(name)
        @top
      end
    end
  end
end
