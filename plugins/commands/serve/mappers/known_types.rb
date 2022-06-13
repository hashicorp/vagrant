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
            logger.error { "array mapping to proto failed: #{err}" }
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
              r = mapper.map(v)
              # unwrap any wrapper classes here before assigning
              r = r.value if r.is_a?(Type)
              r
            end
          rescue => err
            logger.error { "proto mapping to array failed: #{err}" }
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
            entries = hash.map do |k, v|
              next if v.is_a?(Log4r::Logger)
              SDK::Args::HashEntry.new(
                key: mapper.map(k, to: Google::Protobuf::Any),
                value: mapper.map(v, to: Google::Protobuf::Any),
              )
            end.compact
            SDK::Args::Hash.new(entries: entries)
          rescue => err
            logger.error { "hash mapping to proto failed: #{err}" }
            logger.trace { "#{err}\n#{err.backtrace.join("\n")}" }
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
            h = Hash.new.tap do |result|
              proto.entries.each do |entry|
                # Convert our key and value to native types
                k = mapper.map(entry.key)
                v = mapper.map(entry.value)
                # If the key or the value is a wrapper type,
                # extract the value from it
                k = k.value if k.is_a?(Type)
                v = v.value if v.is_a?(Type)
                result[k] = v
              end
            end
            Vagrant::Util::HashWithIndifferentAccess.new(h)
          rescue => err
            logger.error { "proto mapping to hash failed: #{err}" }
            raise
          end
        end
      end

      class SymbolToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Symbol)],
            output: SDK::Args::Symbol,
            func: method(:converter),
          )
        end

        def converter(input)
          SDK::Args::Symbol.new(str: input.to_s)
        end
      end

      class SymbolProtoToAny < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Symbol)],
            output: Google::Protobuf::Any,
            func: method(:converter),
          )
        end

        def converter(input)
          Google::Protobuf::Any.pack(input)
        end
      end

      class SymbolProtoToSymbol < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Symbol)],
            output: Symbol,
            func: method(:converter),
          )
        end

        def converter(input)
          input.str.to_sym
        end
      end

      class ClassToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Class)],
            output: SDK::Args::Class,
            func: method(:converter),
          )
        end

        def converter(c)
          SDK::Args::Class.new(name: c.name)
        end
      end

      class ClassFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Class)],
            output: Class,
            func: method(:converter),
          )
        end

        def converter(c)
          if c.name.to_s.empty?
            c.name = "Vagrant::Config::V2::DummyConfig"
            # raise "no class name defined for conversion! (value: #{c})"
          end
          c.name.split("::").inject(Object) { |memo, name|
            memo.const_get(name)
          }
        end
      end

      class RangeToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Range)],
            output: SDK::Args::Range,
            func: method(:converter),
          )
        end

        def converter(r)
          SDK::Args::Range.new(start: r.first, end: r.last)
        end
      end

      class RangeFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Range)],
            output: Range,
            func: method(:converter),
          )
        end

        def converter(r)
          Range.new(r.start, r.end)
        end
      end
    end
  end
end
