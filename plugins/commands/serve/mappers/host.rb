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
      class HostFromSpec < Mapper
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
      class HostFromProto < Mapper
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
    end
  end
end
