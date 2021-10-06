require "google/protobuf/wrappers_pb"

module VagrantPlugins
  module CommandServe
    class Mappers
      Google::Protobuf.constants.grep(/.Value$/).each do |name|
        value = Google::Protobuf.const_get(name)
        next if !value.is_a?(Class)
        type = value.new.respond_to?(:value) ?
          value.new.value.class :
          value.new.values.class
        klass = Class.new(Mapper).class_eval "
          def initialize
            super(
              inputs: [Input.new(type:#{value.name})],
              output: #{type.name},
              func: method(:converter)
            )
          end

          def self.name
            \"#{name}\"
          end

          def converter(proto)
            proto.value
          end
        "
        self.const_set(
          name,
          klass
        )
      end
    end
  end
end
