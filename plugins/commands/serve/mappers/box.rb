# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a box client from a proto instance
      class BoxFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Box)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Box, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Box.load(proto, broker: broker)
        end
      end

      class BoxClientToBox < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::Box)
          end
          super(inputs: inputs, output: Vagrant::Box, func: method(:converter))
        end

        def converter(box_client)
          Vagrant::Box.new(
            box_client.name,
            box_client.provider.to_sym,
            box_client.version,
            Pathname.new(box_client.directory),
            client: box_client
          )
        end
      end

      class BoxMetadataFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::BoxMetadata)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::BoxMetadata, func: method(:converter))
        end

        def converter(proto, broker)
          Client::BoxMetadata.load(proto, broker: broker)
        end
      end
    end
  end
end
