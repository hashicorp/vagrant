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
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            statebag = mapper.funcspec_map(req, expect: Client::StateBag)
            plugin = Vagrant.plugin("2").local_manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            host = plugin.new
            begin
              detected = host.detect?(statebag)
            rescue => err
              logger.debug("error encountered detecting host: #{err.class} - #{err}")
              detected = false
            end
            logger.debug("detected #{detected} for host #{plugin_name}")
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
            host_hash = Vagrant.plugin("2").local_manager.hosts[plugin_name.to_s.to_sym].to_a
            plugin = host_hash.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            SDK::Platform::ParentResp.new(
              parent: host_hash.last
            )
          end
        end
      end
    end
  end
end
