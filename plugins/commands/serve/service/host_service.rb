# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class HostService < ProtoService(SDK::HostService::Service)

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          super
          caps = Vagrant.plugin("2").local_manager.host_capabilities
          default_args = {
            Vagrant::Environment => SDK::Args::Project
          }
          initialize_capability_platform!(caps, default_args)
        end

        def detect_spec(*_)
          funcspec(
            args: [
              SDK::Args::StateBag,
            ],
            result: SDK::Platform::DetectResp,
          )
        end

        def detect(req, ctx)
          with_plugin(ctx, :hosts, broker: broker) do |plugin, info|
            statebag = mapper.funcspec_map(req, expect: Client::StateBag)
            host = load_host(plugin)
            begin
              detected = host.detect?(statebag)
            rescue => err
              logger.debug("error encountered detecting host: #{err.class} - #{err}")
              detected = false
            end
            logger.debug("detected #{detected} for host #{info.plugin_name}")
            SDK::Platform::DetectResp.new(
              detected: detected,
            )
          end
        end

        def parent_spec(*_)
          funcspec(
            result: SDK::Platform::ParentResp
          )
        end

        def parent(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            host_info = Array(Vagrant.plugin("2").local_manager.hosts[plugin_name])
            if !host_info.first
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            # TODO: shouldn't this be checking length?
            SDK::Platform::ParentResp.new(
              parent: host_info.last
            )
          end
        end

        def load_host(klass)
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
