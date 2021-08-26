module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a target client from a FuncSpec value
      class TargetFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Target" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target.load(proto.value.value, broker: broker)
        end
      end

      # Build a target client from a proto instance
      class TargetFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Target)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target.load(proto, broker: broker)
        end
      end

      # Build a target client from a serialized proto string
      class TargetFromString < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: String)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target.load(proto, broker: broker)
        end
      end
    end
  end
end
