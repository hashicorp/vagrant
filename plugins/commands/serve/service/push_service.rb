# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Service
      class PushService < ProtoService(SDK::PushService::Service)
        def push(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            env = mapper.funcspec_map(req, expect: [Vagrant::Environment])

            # Here we are reusing logic from Environment#push, which does the
            # work of looking up the right plugin and scoping down the relevant
            # config from the vagrantfile
            #
            # We are already in a remote lookup loop, so we pass in the local
            # manager to ensure that the local plugin is being looked up.
            env.push(plugin_name, manager: Vagrant.plugin("2").local_manager)

            # The GRPC spec for push plugins has them just returning an empty
            # response on success. The assumption is that they'll print their
            # user feedback directly to the UI as necessary, and they can raise
            # exceptions for error conditions.
            Empty.new
          end
        end

        def push_spec(*_)
          funcspec(
            args: [
              SDK::Args::Project,
            ]
          )
        end
      end
    end
  end
end
