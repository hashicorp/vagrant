require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Mappers
      # class KnownTypes < Mapper
      #   def initialize
      #     inputs = [].tap do |i|
      #       i << Input.new(type: Google::Protobuf::Value)
      #     end
      #     super(inputs: inputs, output: Object, func: method(:converter))
      #   end

      #   def converter(proto)
      #     proto.to_ruby
      #   end
      # end

      [NilClass, Numeric, String, TrueClass, FalseClass,
        Struct, Hash, Google::Protobuf::ListValue, Array].each do |type|
        Class.new(Mapper).class_eval("
          def self.name
            '#{type.name}ToProto'
          end

          def to_s
            '<#{type.name}ToProto:' + object_id.to_s + '>'
          end

          def initialize
            super(
              inputs: [Input.new(type: #{type.name})],
              output: Google::Protobuf::Value,
              func: method(:converter),
            )
          end

          def converter(input)
            Google::Protobuf::Value.new.tap { |v| v.from_ruby(input) }
          end
        ")
      end
    end
  end
end
