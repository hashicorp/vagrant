module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a command arguments from a FuncSpec value
      class CommandArgumentsProtoFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Command.Arguments" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: SDK::Command::Arguments, func: method(:converter))
        end

        def converter(proto)
          SDK::Command::Arguments.decode(proto.value.value)
        end
      end
    end
  end
end
