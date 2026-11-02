# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class CorePluginManagerFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::CorePluginManager),
              Input.new(type: Broker),
            ],
            output: Client::CorePluginManager,
            func: method(:converter)
          )
        end

        def converter(proto, broker)
          Client::CorePluginManager.load(proto, broker: broker)
        end
      end

      class CorePluginManagerProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.CorePluginManager" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::CorePluginManager,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::CorePluginManager.decode(fv.value.value)
        end
      end

    end
  end
end
