require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class HostService < Hashicorp::Vagrant::Sdk::HostService::Service

        include CapabilityPlatformService

        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::ExceptionLogger

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").manager.host_capabilities
          default_args = [
            # Always get a target to pass the guest capability
            SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Project",
              name: "",
            ),
          ]
          initialize_capability_platform!(caps, default_args)
          super(*args, **opts, &block)
        end

        def detect_spec(*_)
          SDK::FuncSpec.new(
            name: "detect_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Host.DetectResp",
              name: "",
            ]
          )
        end

        def detect(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            plugin = Vagrant.plugin("2").manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            host = plugin.new
            SDK::Host::DetectResp.new(
              detected: host.detect?({}), # TODO(spox): argument should be env/state bag
            )
          end
        end

        def parents_spec(*_)
          SDK::FuncSpec.new(
            name: "parents_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Host.ParentsResp",
              name: "",
            ]
          )
        end

        def parents(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            plugin = Vagrant.plugin("2").manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            SDK::Host::ParentsResp.new(
              parents: plugin.new.parents
            )
          end
        end
      end
    end
  end
end
