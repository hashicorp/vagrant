# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      module CapabilityPlatformService

        def self.included(klass)
          klass.class_eval do
            attr_reader :capabilities, :default_args
          end
        end

        def initialize_capability_platform!(capabilities, default_args)
          @capabilities = capabilities
          @default_args = default_args
        end

        def has_capability_spec(*_)
          funcspec(
            args: [
              SDK::Args::NamedCapability,
            ],
            result: SDK::Platform::Capability::CheckResp,
          )
        end

        def has_capability(req, ctx)
          with_info(ctx, broker: broker) do |info|
            cap_name = mapper.funcspec_map(req)
            plugin_name = info.plugin_name
            logger.debug("checking for #{cap_name.inspect} capability in #{plugin_name}")

            caps_registry = @capabilities[plugin_name.to_sym]
            has_cap = caps_registry.key?(cap_name.to_sym)

            SDK::Platform::Capability::CheckResp.new(
              has_capability: has_cap
            )
          end
        end

        def capability_spec(req, ctx)
          funcspec(
            args: default_args.values + [
              SDK::Args::Direct
            ],
            result: SDK::Platform::Capability::Resp,
          )
        end

        def capability(req, ctx)
          with_info(ctx, broker: broker) do |info|
            cap_name = req.name.to_sym
            plugin_name = info.plugin_name.to_sym

            logger.debug("executing capability #{cap_name} on plugin #{plugin_name}")

            caps_registry = capabilities[plugin_name]
            target_cap = caps_registry.get(cap_name)

            if target_cap.nil?
              raise Vagrant::Errors::CapabilityNotFound,
                cap:  cap_name.inspect,
                host: plugin_name
            end

            args = mapper.funcspec_map(
              req.func_args,
              expect: default_args.keys + [Type::Direct]
            )

            args = capability_arguments(args)
            cap_method = target_cap.method(cap_name)

            result = cap_method.call(*args)

            logger.debug("got result #{result}")
            if result.nil? || (result.respond_to?(:empty?) && result.empty?)
              logger.debug("got empty result, returning empty response")
              return SDK::Platform::Capability::Resp.new(
                result: nil
              )
            end

            val = mapper.map(result, to: Google::Protobuf::Any)
            SDK::Platform::Capability::Resp.new(
              result: val
            )
          end
        end

        def capability_arguments(args)
          direct = args.pop
          args + direct.arguments
        end
      end
    end
  end
end
