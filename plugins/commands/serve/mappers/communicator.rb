module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a communicator command arguments from a FuncSpec value
      class CommunicatorCommandArgumentsFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Communicator.Command" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: SDK::Communicator::Command, func: method(:converter))
        end

        def converter(proto)
          SDK::Communicator::Command.decode(proto.value.value)
        end
      end

      # Build a communicator path from a FuncSpec value
      class CommunicatorPathFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.NamedPaths" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: SDK::Args::NamedPaths, func: method(:converter))
        end

        def converter(proto)
          SDK::Args::NamedPaths.decode(proto.value.value)
        end
      end
    end
  end
end
