module VagrantPlugins
  module CommandServe
    module Service
      class PushService < Hashicorp::Vagrant::Sdk::PushService::Service
        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::HasLogger

        include Util::ServiceInfo
        include Util::HasSeeds::Service
        include Util::ExceptionTransformer

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
            result = env.push(plugin_name, manager: Vagrant.plugin("2").local_manager)

            SDK::Push::PushResponse.new(
              exit_code: result.respond_to?(:exit_code) ? result.exit_code : 0
            )
          end
        end

        def push_spec(*_)
          SDK::FuncSpec.new(
            name: "push_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Project",
                name: "",
              ),
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Push.PushResponse",
                name: "",
              ),
            ],
          )
        end
      end
    end
  end
end

