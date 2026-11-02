# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class NamedCapabilityProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.NamedCapability" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::NamedCapability,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::NamedCapability.decode(fv.value.value)
        end
      end

      class NamedCapabilityFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::NamedCapability)],
            output: Symbol,
            func: method(:converter),
          )
        end

        def converter(n)
          n.capability.to_s.to_sym
        end
      end

      # Build a machine client from a FuncSpec value
      class NamedCapabilityFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.NamedCapability" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: Symbol, func: method(:converter))
        end

        def converter(proto)
          SDK::Args::NamedCapability.decode(proto.value.value).
            capability.to_s.to_sym
        end
      end
    end
  end
end
