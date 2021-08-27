require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class GuestService < Hashicorp::Vagrant::Sdk::GuestService::Service

        include CapabilityPlatformService

        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::ExceptionLogger
        LOGGER  = Log4r::Logger.new("vagrant::command::serve::guest")

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").manager.guest_capabilities
          default_args = [
            # Always get a target to pass the guest capability
            SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target",
              name: "",
            ),
          ]
          initialize_capability_platform!(caps, default_args)
          super(*args, **opts, &block)
        end

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
            target = mapper.funcspec_map(req)
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
              parents: plugin.new.parents
            )
          end
        end
      end
    end
  end
end
