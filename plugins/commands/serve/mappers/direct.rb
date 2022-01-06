require "pp"
require "google/protobuf/well_known_types"
require "google/protobuf/wrappers_pb"

module VagrantPlugins
  module CommandServe
    class Mappers
      class DirectFuncSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Direct" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: SDK::Args::Direct, func: method(:converter))
        end

        def converter(proto)
          SDK::Args::Direct.decode(proto.value.value)
        end
      end

      class DirectFromProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::Direct),
              Input.new(type: Mappers),
            ],
            output: Type::Direct,
            func: method(:converter),
          )
        end

        def converter(direct, mappers)
          args = direct.arguments.map do |v|
            logger.debug("converting direct argument #{v} to something useful")
            mappers.map(v)
          end
          Type::Direct.new(arguments: args)
        end
      end

      class DirectToProto < Mapper
        include Util::HasLogger

        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Type::Direct)
            i << Input.new(type: Mappers)
          end
          super(inputs: inputs, output: SDK::Args::Direct, func: method(:converter))
        end

        def converter(d, mappers)
          args = d.args.map do |a|
            begin
              logger.debug("direct argument list item map to any: #{a.pretty_inspect}")
              mappers.map(a, to: Google::Protobuf::Any)
            rescue => err
              raise "Failed to map value #{a} - #{err}\n#{err.backtrace.join("\n")}"
            end
          end
          SDK::Args::Direct.new(arguments: args)
        end
      end
    end
  end
end
