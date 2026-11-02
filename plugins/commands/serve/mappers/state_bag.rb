# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class StateBagProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.StateBag" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::StateBag,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::StateBag.decode(fv.value.value)
        end
      end

      class StateBagFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::StateBag),
              Input.new(type: Broker),
            ],
            output: Client::StateBag,
            func: method(:converter)
          )
        end

        def converter(proto, broker)
          Client::StateBag.load(proto, broker: broker)
        end
      end

      # Extracts a statebag from a Funcspec value
      class StateBagFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.StateBag" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::StateBag, func: method(:converter))
        end

        def converter(proto, broker)
          Client::StateBag.load(proto.value.value, broker: broker)
        end
      end
    end
  end
end
