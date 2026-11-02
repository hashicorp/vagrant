# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a provider client from a FuncSpec value
      class ProviderFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Provider" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Provider, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Provider.load(proto.value.value, broker: broker)
        end
      end

      # Build a provider client from a proto instance
      class ProviderFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Provider)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Provider, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Provider.load(proto, broker: broker)
        end
      end
    end
  end
end
