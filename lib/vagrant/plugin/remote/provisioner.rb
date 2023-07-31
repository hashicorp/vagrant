# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      class Provisioner < V2::Provisioner
        # Add an attribute accesor for the client
        attr_accessor :client

        # Provisioner plugins receive machine and config on init that they
        # expect to set as instance variables and use later. When we're in
        # server mode, this instance is only a client, and the local plugin
        # is going to be reinstantiated over on the server side. We will still
        # needs these two pieces of state on the server side, so in order to
        # get them over there, we tack them onto the front as args for each
        # client method call. The server will then peel off those two args
        # and use them to initialize the plugin in local mode before it
        # dispatches the method call.
        #
        # @see Vagrant::Plugin::V2::Provisioner#initialize the local init
        #      method we're overriding
        # @see Vagrant::CommandServe::Service::ProvisionerService where we
        #      pop off the two args and reinitialize a local plugin
        def initialize(machine, config, **opts)
          @_machine = machine
          @_config = config
          if opts[:client].nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}`"
          end
          @client = opts[:client]
          super(machine, config)
        end

        def cleanup
          client.provision(@_machine, @_config)
        end

        def configure(root_config)
          client.configure(@_machine, @_config, root_config)
        end

        def provision
          client.provision(@_machine, @_config)
        end
      end
    end
  end
end
