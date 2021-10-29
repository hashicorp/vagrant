require "google/protobuf/wrappers_pb"

module VagrantPlugins
  module CommandServe
    class Mappers
      Google::Protobuf.constants.grep(/.Value$/).each do |name|
        value = Google::Protobuf.const_get(name)
        next if !value.is_a?(Class)
        if value.instance_methods.include?(:value)
          type = value.new.value.class
        elsif value.instance_methods.include?(:values)
          type = Array
        elsif value.instance_methods.include?(:fields)
          type = Hash
        end
        type = value.new.respond_to?(:value) ?
          value.new.value.class :
          value.new.values.class
        n = type.name.to_s.split("::").last
        Class.new(Mapper).class_eval "
          def initialize
            super(
              inputs: [Input.new(type: #{value.name})],
              output: #{type.name},
              func: method(:converter)
            )
          end

          def self.name
            '#{name}To#{n}'
          end

          def to_s
            '<#{name}To#{n}:' + object_id.to_s + '>'
          end

          def converter(proto)
            if proto.respond_to?(:value)
              proto.value
            elsif proto.respond_to?(:values)
              proto.values.to_a
            else
              proto.fields.to_h
            end
          end
        "
      end
    end
  end
end
