require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Mappers
      class NilToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: NilClass)],
            output: SDK::Args::Null,
            func: method(:converter),
          )
        end

        def converter(*_)
          SDK::Args::Null.new
        end
      end

      class NilFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Null)],
            output: NilClass,
            func: method(:converter),
          )
        end

        def converter(*_)
          nil
        end
      end

      class ArrayToProto < Mapper

        include Util::HasLogger

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
          begin
            r = array.map do |v|
              mapper.map(v, to: Google::Protobuf::Any)
            end
            SDK::Args::Array.new(list: r)
          rescue => err
            logger.error("array mapping to proto failed: #{err}")
            raise
          end
        end
      end

      class ArrayFromProto < Mapper

        include Util::HasLogger

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
          begin
            proto.list.map do |v|
              mapper.map(v)
            end
          rescue => err
            logger.error("proto mapping to array failed: #{err}")
            raise
          end
        end
      end

      class ClassToString < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Class)],
            output: String,
            func: method(:converter),
          )
        end

        def converter(cls)
          cls.to_s
        end
      end

      class HashToProto < Mapper

        include Util::HasLogger

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
          begin
            fields = Hash.new.tap do |f|
              hash.each_pair do |k, v|
                r = mapper.map(v, to: Google::Protobuf::Any)
                f[k] = r
              end
            end
            SDK::Args::Hash.new(fields: fields)
          rescue => err
            logger.error("hash mapping to proto failed: #{err}")
            raise
          end
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

        include Util::HasLogger

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
          begin
            Hash.new.tap do |result|
              proto.fields.each do |k, v|
                r = mapper.map(v)
                result[k.to_sym] = r
              end
            end
          rescue => err
            logger.error("proto mapping to hash failed: #{err}")
            raise
          end
        end
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
    end
  end
end
