require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class HostService < Hashicorp::Vagrant::Sdk::HostService::Service

        include CapabilityPlatformService

        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::ExceptionLogger
        LOGGER  = Log4r::Logger.new("vagrant::command::serve::host")

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
          super
        end

        def detect_spec(*_)
          # TODO: Add statebad as an arg
          SDK::FuncSpec.new(
            name: "detect_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.StateBag",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Platform.DetectResp",
              name: "",
            ]
          )
        end

        def detect(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            statebag = mapper.funcspec_map(req)
            plugin = Vagrant.plugin("2").manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            host = plugin.new
            begin
              detected = host.detect?(statebag)
            rescue => err
              LOGGER.debug("error encountered detecting host: #{err.class} - #{err}")
              detected = false
            end
            LOGGER.debug("detected #{detected} for host #{plugin_name}")
            SDK::Platform::DetectResp.new(
              detected: detected,
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
            p = plugin.new.parents
            SDK::Platform::ParentsResp.new(
              parents: p
            )
          end
        end
      end
    end
  end
end
