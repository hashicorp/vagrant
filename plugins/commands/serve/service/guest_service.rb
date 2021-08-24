require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class GuestService < Hashicorp::Vagrant::Sdk::GuestService::Service
        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::ExceptionLogger
        LOGGER  = Log4r::Logger.new("vagrant::command::serve::guest")

        def detect_spec(*_)
          SDK::FuncSpec.new(
            name: "detect_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target",
                name: "",
              )
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Platform.DetectResp",
                name: "",
              ),
            ],
          )
        end

        def detect(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            target = mapper.funcspec_map(req.args)

            project = target.project
            env = Vagrant::Environment.new({client: project})
            machine = env.machine(target.name.to_sym, target.provider_name.to_sym)
            plugin = Vagrant.plugin("2").manager.guests[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              LOGGER.debug("Failed to locate guest plugin for: #{plugin_name}")
              raise "Failed to locate guest plugin for: #{plugin_name.inspect}"
            end
            guest = plugin.new
            begin
              detected = guest.detect?(machine)
            rescue => err
              LOGGER.debug("error encountered detecting guest: #{err.class} - #{err}")
              detected = false
            end
            LOGGER.debug("detected #{detected} for guest #{plugin_name}")
            SDK::Platform::DetectResp.new(
              detected: detected,
            )
          end
        end

        def parents_spec(*_)
          SDK::FuncSpec.new(
            name: "parents_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Platform.ParentsResp",
              name: "",
            ]
          )
        end

        def parents(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            plugin = Vagrant.plugin("2").manager.guests[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate guest plugin for: #{plugin_name.inspect}"
            end
            SDK::Platform::ParentsResp.new(
              parents: plugin.new.cap_host_chain
            )
          end
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

            caps_registry = Vagrant.plugin("2").manager.guest_capabilities[plugin_name.to_sym]
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
            caps_registry = Vagrant.plugin("2").manager.guest_capabilities[plugin_name]

            target_cap = caps_registry.get(cap_name)
            args = target_cap.method(cap_name).parameters
            # The first argument is always a machine, drop it
            args.shift

            cap_args = [
              # Always get a target to pass the guest capability
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target",
                name: "",
              ),
            ]

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
            caps_registry = Vagrant.plugin("2").manager.guest_capabilities[plugin_name]
            target_cap = caps_registry.get(cap_name)

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
