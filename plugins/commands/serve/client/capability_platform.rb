# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Client
      module CapabilityPlatform
        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def has_capability_func
          spec = client.has_capability_spec(Empty.new)
          cb = proc do |args|
            client.has_capability(args).has_capability
          end
          [spec, cb]
        end

        # @param [Symbol] cap_name Capability name
        # @return [Boolean]
        def has_capability?(cap_name)
          run_func(
            SDK::Args::NamedCapability.new(
              capability: cap_name.to_s
            )
          )
        end

        # Generate callback and spec for required arguments
        #
        # @param cap_name [String] Name of capability
        # @return [SDK::FuncSpec, Proc]
        def capability_func(cap_name)
          spec = client.capability_spec(
            SDK::Platform::Capability::NamedRequest.new(
              name: cap_name,
            )
          )
          cb = lambda do |name, args|
            result = client.capability(
              SDK::Platform::Capability::NamedRequest.new(
                name: name,
                func_args: args,
              )
            )
            return nil if result.nil? || result.result.nil?
            mapper.map(SDK::Args::Direct.new(arguments: [result.result])).arguments.first
          end
          [spec, cb]
        end

        # @param [Symbol] cap_name Name of the capability
        def capability(cap_name, *args)
          logger.debug("executing capability #{cap_name}")
          spec, cb = capability_func(cap_name)
          cb.call(cap_name,
            generate_funcspec_args(spec,
              Type::Direct.new(value: args), *args))
        end
      end
    end
  end
end
