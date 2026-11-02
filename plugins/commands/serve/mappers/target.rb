# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class TargetProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Target" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Target,
            func: method(:converter)
          )
        end

        def converter(fv)
          SDK::Args::Target.decode(fv.value.value)
        end
      end

      # Build a target client from a FuncSpec value
      class TargetFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Target" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target.load(proto.value.value, broker: broker)
        end
      end

      # Build a target client from a proto instance
      class TargetFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Target)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target.load(proto, broker: broker)
        end
      end

      class TargetToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Client::Target)],
            output: SDK::Args::Target,
            func: method(:converter),
          )
        end

        def converter(t)
          return t.to_proto if
            t.class == Client::Target
          t.client.as_target(Empty.new)
        end
      end
    end
  end
end
