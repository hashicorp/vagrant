# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a guest client from a proto instance
      class PushFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Push)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Push, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Push.load(proto, broker: broker)
        end
      end
    end
  end
end
