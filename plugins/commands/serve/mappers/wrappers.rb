# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "google/protobuf/wrappers_pb"

module VagrantPlugins
  module CommandServe
    class Mappers

      # Boolean mappers

      class BooleanToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Type::Boolean)],
            output: Google::Protobuf::BoolValue,
            func: method(:converter),
          )
        end

        def converter(bool)
          Google::Protobuf::BoolValue.new(value: bool.value)
        end
      end

      class BooleanFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::BoolValue)],
            output: Type::Boolean,
            func: method(:converter),
          )
        end

        def converter(proto)
          Type::Boolean.new(value: proto.value)
        end
      end

      class TrueToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: TrueClass)],
            output: Google::Protobuf::BoolValue,
            func: method(:converter)
          )
        end

        def converter(v)
          Google::Protobuf::BoolValue.new(value: v)
        end
      end

      class FalseToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: FalseClass)],
            output: Google::Protobuf::BoolValue,
            func: method(:converter),
          )
        end

        def converter(v)
          Google::Protobuf::BoolValue.new(value: v)
        end
      end

      # Bytes mappers

      class BytesFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::BytesValue)],
            output: String,
            func: method(:converter)
          )
        end

        def converter(proto)
          proto.value
        end
      end

      # Numeric mappers

      class DoubleFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::DoubleValue)],
            output: Float,
            func: method(:converter),
          )
        end

        def converter(num)
          num.value
        end
      end

      class FloatFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::FloatValue)],
            output: Float,
            func: method(:converter),
          )
        end

        def converter(num)
          num.value
        end
      end

      class FloatToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Float)],
            output: Google::Protobuf::FloatValue,
            func: method(:converter),
          )
        end

        def converter(v)
          Google::Protobuf::FloatValue.new(value: v)
        end
      end

      class Int32FromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::Int32Value)],
            output: Integer,
            func: method(:converter),
          )
        end

        def converter(v)
          v.value
        end
      end

      class Int64FromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::Int64Value)],
            output: Integer,
            func: method(:converter)
          )
        end

        def converter(v)
          v.value
        end
      end

      class UInt32FromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::UInt32Value)],
            output: Integer,
            func: method(:converter)
          )
        end

        def converter(v)
          v.value
        end
      end

      class UInt64FromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::UInt64Value)],
            output: Integer,
            func: method(:converter)
          )
        end

        def converter(v)
          v.value
        end
      end


      class IntegerToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Integer)],
            output: Google::Protobuf::Int64Value,
            func: method(:converter)
          )
        end

        def converter(num)
          Google::Protobuf::Int64Value.new(value: num)
        end
      end

      # String mappers

      class StringToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: String)],
            output: Google::Protobuf::StringValue,
            func: method(:converter)
          )
        end

        def converter(s)
          Google::Protobuf::StringValue.new(value: s.to_s)
        end
      end

      class StringFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Google::Protobuf::StringValue)],
            output: String,
            func: method(:converter)
          )
        end

        def converter(proto)
          proto.value
        end
      end
    end
  end
end
