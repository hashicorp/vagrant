# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class GuestService < ProtoService(SDK::GuestService::Service)

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          super
          caps = Vagrant.plugin("2").local_manager.guest_capabilities
          default_args = {
            Client::Target::Machine => SDK::Args::Target::Machine
          }
          initialize_capability_platform!(caps, default_args)
        end

        def detect_spec(*_)
          funcspec(
            args: [SDK::Args::Target::Machine],
            result: SDK::Platform::DetectResp,
          )
        end

        def detect(req, ctx)
          with_plugin(ctx, :guests, broker: broker) do |plugin, info|
            machine = mapper.funcspec_map(req, expect: Vagrant::Machine)
            guest = load_guest(plugin)
            begin
              detected = guest.detect?(machine)
            rescue => err
              logger.debug("error encountered detecting guest: #{err.class} - #{err}")
              detected = false
            end
            logger.debug("detected #{detected} for guest #{info.plugin_name}")
            SDK::Platform::DetectResp.new(
              detected: detected,
            )
          end
        end

        def parent_spec(*_)
          funcspec(result: SDK::Platform::ParentResp)
        end

        def parent(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            guest_info = Array(Vagrant.plugin("2").local_manager.guests[plugin_name])
            if !guest_info.first
              raise "Failed to locate guest plugin for: #{plugin_name.inspect}"
            end
            # TODO: shouldn't this be checking length?
            SDK::Platform::ParentResp.new(
              parent: guest_info.last
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

        def load_guest(klass)
          key = cache.key(klass)
          return cache.get(key) if cache.registered?(key)
          klass.new.tap do |i|
            cache.register(key, i)
          end
        end
      end
    end
  end
end
