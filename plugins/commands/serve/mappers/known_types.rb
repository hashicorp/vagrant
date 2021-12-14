require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Mappers
      [NilClass, Numeric, String, TrueClass, FalseClass,
        Struct, Google::Protobuf::ListValue].each do |type|
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

      class SymbolToString < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Symbol)],
            output: String,
            func: method(:converter),
          )
        end

        def converter(sym)
          sym.to_s
        end
      end

      class HashToProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Hash),
              Input.new(type: Mappers),
            ],
            output: SDK::Args::Hash,
            func: method(:converter),
          )
        end

        def converter(hash, mapper)
          fields = Hash.new.tap do |f|
            hash.each_pair do |k, v|
              r = mapper.map(v, to: Google::Protobuf::Any)
              f[k] = r
            end
          end
          SDK::Args::Hash.new(fields: fields)
        end
      end

      class HashProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Hash" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Hash,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::Hash.decode(fv.value.value)
        end
      end

      class HashFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::Hash),
              Input.new(type: Mappers)
            ],
            output: Hash,
            func: method(:converter),
          )
        end

        def converter(proto, mapper)
          Hash.new.tap do |result|
            proto.fields.each do |k, v|
              r = mapper.map(v)
              # result[k.to_s] = r
              result[k.to_sym] = r
            end
          end
        end
      end

      class ArrayToProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Array),
              Input.new(type: Mappers),
            ],
            output: SDK::Args::Array,
            func: method(:converter),
          )
        end

        def converter(array, mapper)
          r = array.map do |v|
            mapper.map(v, to: Google::Protobuf::Any)
          end
          SDK::Args::Array.new(list: r)
        end
      end

      class ArrayFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::Array),
              Input.new(type: Mappers),
            ],
            output: Array,
            func: method(:converter),
          )
        end

        def converter(proto, mapper)
          proto.list.map do |v|
            mapper.map(v)
          end
        end
      end
    end
  end
end
