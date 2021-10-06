module VagrantPlugins
  module CommandServe
    class Mappers
      # Extracts a string capability name from a Funcspec value
      class NamedCapability < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.NamedCapability" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: String, func: method(:converter))
        end

        def converter(proto)
          SDK::Args::NamedCapability.decode(proto.value.value).capability
        end
      end
    end
  end
end
