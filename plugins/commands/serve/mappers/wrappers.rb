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

        Class.new(Mapper) do
          def converter(proto)
            v = extract(proto)
            embiggen(v)
          end

          def extract(v)
            if v.respond_to?(:value)
              v = v.value
            elsif v.respond_to?(:values)
              v = v.values.to_a
            elsif v.respond_to?(:fields)
              v = v.fields.to_h
            else
              v
            end
          end

          def embiggen(v)
            return v if !v.is_a?(Enumerable)
            v.class[
              v.map { |nv|
                embiggen(extract(nv))
              }
            ]
          end
        end.class_eval "
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
        "
      end
    end
  end
end
