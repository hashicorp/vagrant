module Vagrant
  module Plugin
    module V2
      # This is the base class for a provisioner for the V2 API. A provisioner
      # is primarily responsible for installing software on a Vagrant guest.
      class Provisioner
        attr_reader :machine
        attr_reader :config

        # Initializes the provisioner with the machine that it will be
        # provisioning along with the provisioner configuration (if there
        # is any).
        #
        # The provisioner should _not_ do anything at this point except
        # initialize internal state.
        #
        # @param [Machine] machine The machine that this will be provisioning.
        # @param [Object] config Provisioner configuration, if one was set.
        def initialize(machine, config)
          @machine = machine
          @config  = config
        end

        # Called with the root configuration of the machine so the provisioner
        # can add some configuration on top of the machine.
        #
        # During this step, and this step only, the provisioner should modify
        # the root machine configuration to add any additional features it
        # may need. Examples include sharing folders, networking, and so on.
        # This step is guaranteed to be called before any of those steps are
        # done so the provisioner may do that.
        #
        # No return value is expected.
        def configure(root_config)
        end

        # This is the method called when the actual provisioning should be
        # done. The communicator is guaranteed to be ready at this point,
        # and any shared folders or networks are already setup.
        #
        # No return value is expected.
        def provision
        end

        # This is the method called when destroying a machine that allows
        # for any state related to the machine created by the provisioner
        # to be cleaned up.
        def cleanup
        end
      end
    end
  end
end
