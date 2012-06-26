module Vagrant
  module Plugin
    module V1
      # This is the base class for a provisioner for the V1 API. A provisioner
      # is primarily responsible for installing software on a Vagrant guest.
      class Provisioner
        # The environment which provisioner is running in. This is the
        # action environment, not a Vagrant::Environment.
        attr_reader :env

        # The configuration for this provisioner. This will be an instance of
        # the `Config` class which is part of the provisioner.
        attr_reader :config

        def initialize(env, config)
          @env    = env
          @config = config
        end

        # This method is expected to return a class that is used for
        # configuring the provisioner. This return value is expected to be
        # a subclass of {Config}.
        #
        # @return [Config]
        def self.config_class
        end

        # This is the method called to "prepare" the provisioner. This is called
        # before any actions are run by the action runner (see {Vagrant::Actions::Runner}).
        # This can be used to setup shared folders, forward ports, etc. Whatever is
        # necessary on a "meta" level.
        #
        # No return value is expected.
        def prepare
        end

        # This is the method called to provision the system. This method
        # is expected to do whatever necessary to provision the system (create files,
        # SSH, etc.)
        def provision!
        end

        # This is the method called to when the system is being destroyed
        # and allows the provisioners to engage in any cleanup tasks necessary.
        def cleanup
        end
      end
    end
  end
end
