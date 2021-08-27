require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      module CapabilityPlatformService
        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::ExceptionLogger

        def initialize_capability_platform!(capabilities, default_args)
          @capabilities = capabilities
          @default_args = default_args
        end

       
        def has_capability_spec(*_)
          SDK::FuncSpec.new(
            name: "has_capability_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.NamedCapability",
                name: "",
              )
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Platform.Capability.CheckResp",
                name: "",
              ),
            ],
          )
        end

        def has_capability(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            cap_name = req.args.detect { |a|
              a.type == "hashicorp.vagrant.sdk.Args.NamedCapability"
            }&.value&.value.strip.gsub("\b", "")
            plugin_name = info.plugin_name
            LOGGER.debug("checking for #{cap_name} capability in #{plugin_name}")

            caps_registry = @capabilities[plugin_name.to_sym]
            has_cap = caps_registry.key?(cap_name.to_sym)

            SDK::Platform::Capability::CheckResp.new(
              has_capability: has_cap
            )
          end
        end

        def capability_spec(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            cap_name = req.name.to_sym
            plugin_name = info.plugin_name.to_sym
            LOGGER.debug("generating capabillity spec for #{cap_name} capability in #{plugin_name}")
            caps_registry = @capabilities[plugin_name]

            target_cap = caps_registry.get(cap_name)
            args = target_cap.method(cap_name).parameters
            # The first argument is always a machine, drop it
            args.shift

            cap_args = default_args

            # TODO: take the rest of `args` and create entries for them in 
            # `cap_args`

            return SDK::FuncSpec.new(
              name: "has_capability_spec",
              args: cap_args,
              result: [
                SDK::FuncSpec::Value.new(
                  type: "hashicorp.vagrant.sdk.Platform.Capability.Resp",
                  name: "",
                ),
              ],
            )
          end
        end

        def capability(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            LOGGER.debug("executing capability, got req #{req}")
            cap_name = req.name.to_sym
            plugin_name = info.plugin_name.to_sym
            caps_registry = @capabilities[plugin_name]
            target_cap = caps_registry.get(cap_name)

            # TODO: how to get this Target out of the args
            
            # A machine should always be provided to a guest capability
            raw_target = req.func_args.args.detect { |a|
              a.type == "hashicorp.vagrant.sdk.Args.Target"
            }&.value&.value
            target = Client::Target.load(raw_target, broker: broker)
            project = target.project
            env = Vagrant::Environment.new({client: project})
            machine = env.machine(target.name.to_sym, target.provider_name.to_sym)

            cap_method = target_cap.method(cap_name)

            # TODO: pass in other args too
            cap_method.call(machine)
          end
        end
      end
    end
  end
end
