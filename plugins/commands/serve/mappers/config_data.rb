module VagrantPlugins
  module CommandServe
    class Mappers
      class ConfigDataFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.ConfigData" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::ConfigData,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::ConfigData.decode(fv.value.value)
        end
      end

      # NOTE: Disabled
      class ConfigDataFromProto # < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::ConfigData),
              Input.new(type: Mappers)
            ],
            output: Type::ConfigData,
            func: method(:converter),
          )
        end

        def converter(proto, m)
          Type::ConfigData.new(value: m.map(proto.data, to: Hash))
        end
      end

      class ConfigFromConfigDataProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::ConfigData),
              Input.new(type: Mappers),
            ],
            output: Vagrant::Plugin::V2::Config,
            func: method(:converter)
          )
        end

        def converter(c, m)
          base_klass = m.map(c.source, to: Class)
          if [0, -1].include?(base_klass.instance_method(:initialize).arity)
            klass = base_klass
          else
            klass = Class.new(base_klass)
            klass.class_eval("
              def self.class
                #{base_klass.name}
              end
              def initialize
              end
            ")
          end
          instance = klass.new
          data = m.map(c.data, to: Hash)

          if data.key?("__service_finalized")
            instance.finalize!
          end
          data.each_pair do |k, v|
            instance.instance_variable_set("@#{k}", v)
          end
          instance
        end
      end

      class RootConfigToHashProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: Vagrant::Config::V2::Root),
              Input.new(type: Mappers),
            ],
            output: SDK::Args::Hash,
            func: method(:converter),
          )
        end

        def converter(c, m)
          data = c.__internal_state["keys"]
          entries = data.map do |k, v|
            value = m.map(v, to: SDK::Args::ConfigData)
            SDK::Args::HashEntry.new(
              key: m.map(k, to: Google::Protobuf::Any),
              value: Google::Protobuf::Any.pack(value)
            )
          end

          SDK::Args::Hash.new(entries: entries)
        end
      end

      class ConfigToProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: Vagrant::Plugin::V2::Config),
              Input.new(type: Mappers),
            ],
            output: SDK::Args::ConfigData,
            func: method(:converter),
          )
        end

        def converter(c, m)
          data = Hash.new.tap do |h|
            c.instance_variables.each do |v|
              h[v.to_s.sub('@', '')] = c.instance_variable_get(v)
            end
          end

          entries = data.map do |k, v|
            begin
              SDK::Args::HashEntry.new(
                key: m.map(k, to: Google::Protobuf::Any),
                value: m.map(v, to: Google::Protobuf::Any),
              )
            rescue Internal::Graph::Search::NoPathError, TypeError
              logger.warn("failed to map '#{k}' value of type `#{v.class}'")
              nil
            end
          end.compact
          SDK::Args::ConfigData.new(
            data: SDK::Args::Hash.new(entries: entries),
            source: m.map(c.class, to: SDK::Args::Class),
          )
        end
      end

      class RawRubyValueToProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: Object, origin_restricted: true),
              Input.new(type: Mappers),
            ],
            output: SDK::Config::RawRubyValue,
            func: method(:converter)
          )
        end

        def converter(o, m)
          klass = m.map(o.class, to: SDK::Args::Class)
          data = Hash.new.tap do |h|
            o.instance_variables.each do |v|
              h[v.to_s.sub('@', '')] = o.instance_variable_get(v)
            end
          end

          entries = data.map do |k, v|
            next if v.is_a?(Log4r::Logger)
            begin
              SDK::Args::HashEntry.new(
                key: m.map(k, to: Google::Protobuf::Any),
                value: m.map(v, to: Google::Protobuf::Any),
              )
            rescue Internal::Graph::Search::NoPathError, TypeError
              logger.warn("failed to map '#{k}' value of type `#{v.class}'")
              nil
            end
          end.compact
          SDK::Config::RawRubyValue.new(
            source: klass,
            data: SDK::Args::Hash.new(entries: entries)
          )
        end

        def extra_weight
          1_000_000_000_000
        end
      end

      class RawRubyValueFromProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Config::RawRubyValue, origin_restricted: true),
              Input.new(type: Mappers)
            ],
            output: Object,
            func: method(:converter),
          )
        end

        def converter(r, m)
          base_klass = m.map(r.source, to: Class)
          if [0, -1].include?(base_klass.instance_method(:initialize).arity)
            klass = base_klass
          else
            klass = Class.new(base_klass)
            klass.class_eval("
              def self.class
                #{base_klass.name}
              end
              def initialize
              end
            ")
          end
          instance = klass.new
          data = m.map(r.data, to: Hash)

          data.each_pair do |k, v|
            instance.instance_variable_set("@#{k}", v)
          end
          instance
        end
      end
    end
  end
end
