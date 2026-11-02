# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class PluginManagerFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::PluginManager),
              Input.new(type: Broker),
            ],
            output: Client::PluginManager,
            func: method(:converter)
          )
        end

        def converter(proto, broker)
          Client::PluginManager.load(proto, broker: broker)
        end
      end
    end
  end
end
