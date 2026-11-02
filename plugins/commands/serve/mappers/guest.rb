# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class GuestProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Guest" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Guest,
            func: method(:converter)
          )
        end

        def converter(fv)
          SDK::Args::Guest.decode(fv.value.value)
        end
      end

      # Build a guest client from a FuncSpec value
      class GuestFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Guest" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Guest, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Guest.load(proto.value.value, broker: broker)
        end
      end

      # Build a guest client from a proto instance
      class GuestFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Guest)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Guest, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Guest.load(proto, broker: broker)
        end
      end
    end
  end
end
