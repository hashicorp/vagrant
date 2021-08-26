module VagrantPlugins
  module CommandServe
    class Mappers
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

      # Build a guest client from a serialized proto string
      class GuestFromString < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: String)
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
