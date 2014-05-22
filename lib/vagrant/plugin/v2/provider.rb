require "vagrant/capability_host"

module Vagrant
  module Plugin
    module V2
      # This is the base class for a provider for the V2 API. A provider
      # is responsible for creating compute resources to match the needs
      # of a Vagrant-configured system.
      class Provider
        include CapabilityHost

        # This is called early, before a machine is instantiated, to check
        # if this provider is usable. This should return true or false.
        #
        # If raise_error is true, then instead of returning false, this
        # should raise an error with a helpful message about why this
        # provider cannot be used.
        #
        # @param [Boolean] raise_error If true, raise exception if not usable.
        # @return [Boolean]
        def self.usable?(raise_error=false)
          # Return true by default for backwards compat since this was
          # introduced long after providers were being written.
          true
        end

        # Initialize the provider to represent the given machine.
        #
        # @param [Vagrant::Machine] machine The machine that this provider
        #   is responsible for.
        def initialize(machine)
        end

        # This should return an action callable for the given name.
        #
        # @param [Symbol] name Name of the action.
        # @return [Object] A callable action sequence object, whether it
        #   is a proc, object, etc.
        def action(name)
          nil
        end

        # This method is called if the underying machine ID changes. Providers
        # can use this method to load in new data for the actual backing
        # machine or to realize that the machine is now gone (the ID can
        # become `nil`). No parameters are given, since the underlying machine
        # is simply the machine instance given to this object. And no
        # return value is necessary.
        def machine_id_changed
        end

        # This should return a hash of information that explains how to
        # SSH into the machine. If the machine is not at a point where
        # SSH is even possible, then `nil` should be returned.
        #
        # The general structure of this returned hash should be the
        # following:
        #
        #     {
        #       host: "1.2.3.4",
        #       port: "22",
        #       username: "mitchellh",
        #       private_key_path: "/path/to/my/key"
        #     }
        #
        # **Note:** Vagrant only supports private key based authentication,
        # mainly for the reason that there is no easy way to exec into an
        # `ssh` prompt with a password, whereas we can pass a private key
        # via commandline.
        #
        # @return [Hash] SSH information. For the structure of this hash
        #   read the accompanying documentation for this method.
        def ssh_info
          nil
        end

        # This should return the state of the machine within this provider.
        # The state must be an instance of {MachineState}. Please read the
        # documentation of that class for more information.
        #
        # @return [MachineState]
        def state
          nil
        end

        # This is an internal initialize function that should never be
        # overridden. It is used to initialize some common internal state
        # that is used in a provider.
        def _initialize(name, machine)
          initialize_capabilities!(
            name.to_sym,
            { name.to_sym => [Class.new, nil] },
            Vagrant.plugin("2").manager.provider_capabilities,
            machine,
          )
        end
      end
    end
  end
end
