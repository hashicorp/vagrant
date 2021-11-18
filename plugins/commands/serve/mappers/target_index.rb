module VagrantPlugins
  module CommandServe
    class Mappers
      class TargetIndexProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.TargetIndex" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::TargetIndex,
            func: method(:converter)
          )
        end

        def converter(fv)
          SDK::Args::TargetIndex.decode(fv.value.value)
        end
      end

      # Build a target index client from a FuncSpec value
      class TargetIndexFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.TargetIndex" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::TargetIndex, func: method(:converter))
        end

        def converter(proto, broker)
          Client::TargetIndex.load(proto.value.value, broker: broker)
        end
      end

      # Build a target index client from a proto instance
      class TargetIndexFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::TargetIndex)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::TargetIndex, func: method(:converter))
        end

        def converter(proto, broker)
          Client::TargetIndex.load(proto, broker: broker)
        end
      end

      # Build a target index client from a serialized proto string
      class TargetIndexFromString < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: String)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::TargetIndex, func: method(:converter))
        end

        def converter(proto, broker)
          Client::TargetIndex.load(proto, broker: broker)
        end
      end
    end
  end
end
