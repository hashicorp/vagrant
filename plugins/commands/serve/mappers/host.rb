# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class HostProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Host" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Host,
            func: method(:converter)
          )
        end

        def converter(fv)
          SDK::Args::Host.decode(fv.value.value)
        end
      end

      # Build a guest client from a FuncSpec value
      class HostClientFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Host" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Host, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Host.load(proto.value.value, broker: broker)
        end
      end

      # Build a guest client from a proto instance
      class HostClientFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Host)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Host, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Host.load(proto, broker: broker)
        end
      end

      class HostFromClient < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Client::Host),
            ],
            output: Vagrant::Host,
            func: method(:converter)
          )
        end

        def converter(client)
          Vagrant::Host.new(
            client, nil,
            Vagrant.plugin("2").
              local_manager.
              host_capabilities
          )
        end
      end

      class HostProtoFromHost < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Vagrant::Host)
            ],
            output: SDK::Args::Host,
            func: method(:converter),
          )
        end

        def converter(host)
          host.client.to_proto
        end
      end

      class HostProtoFromClient < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Client::Host),
            ],
            output: SDK::Args::Host,
            func: method(:converter)
          )
        end

        def converter(client)
          client.to_proto
        end
      end
    end
  end
end
