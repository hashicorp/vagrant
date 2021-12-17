require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class GuestService < Hashicorp::Vagrant::Sdk::GuestService::Service

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").local_manager.guest_capabilities
          default_args = {
            Client::Target => SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target",
              name: "",
            ),
          }
          initialize_capability_platform!(caps, default_args)
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
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine = mapper.funcspec_map(req, expect: Vagrant::Machine)
            plugin = Vagrant.plugin("2").local_manager.guests[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              logger.debug("Failed to locate guest plugin for: #{plugin_name}")
              raise "Failed to locate guest plugin for: #{plugin_name.inspect}"
            end
            guest = plugin.new
            begin
              detected = guest.detect?(machine)
            rescue => err
              logger.debug("error encountered detecting guest: #{err.class} - #{err}")
              detected = false
            end
            logger.debug("detected #{detected} for guest #{plugin_name}")
            SDK::Platform::DetectResp.new(
              detected: detected,
            )
          end
        end

        def parent_spec(*_)
          SDK::FuncSpec.new(
            name: "parent_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Platform.ParentResp",
              name: "",
            ]
          )
        end

        def parent(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            guest_hash = Vagrant.plugin("2").local_manager.guests[plugin_name.to_s.to_sym].to_a
            plugin = guest_hash.first
            if !plugin
              raise "Failed to locate guest plugin for: #{plugin_name.inspect}"
            end
            SDK::Platform::ParentResp.new(
              parent: guest_hash.last
            )
          end
        end

        def capability_arguments(args)
          target, direct = args
          nargs = direct.args.dup
          if !nargs.first.is_a?(Vagrant::Machine)
            nargs.unshift(mapper.map(target, to: Vagrant::Machine))
          end

          nargs
        end
      end
    end
  end
end
