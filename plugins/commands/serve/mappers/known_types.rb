require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Mappers
      class KnownTypes < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Google::Protobuf::Value)
          end
          super(inputs: inputs, output: Object, func: method(:converter))
        end

        def converter(proto)
          proto.to_ruby
        end
      end
    end
  end
end
