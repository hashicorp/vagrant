# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a guest client from a proto instance
      class ProvisionerFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Provisioner)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Provisioner, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Provisioner.load(proto, broker: broker)
        end
      end
    end
  end
end
