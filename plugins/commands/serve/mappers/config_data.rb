# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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

      class ConfigMergeFromSpec < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Config.Merge" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Config::Merge,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Config::Merge.decode(fv.value.value)
        end
      end

      class ConfigFinalizeFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Config.Finalize" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Config::Finalize,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Config::Finalize.decode(fv.value.value)
        end
      end

      class ConfigFromConfigDataProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::ConfigData),
            ],
            output: Vagrant::Plugin::V2::Config,
            func: method(:converter)
          )
        end

        def converter(c)
          c.to_ruby
        end
      end

      class RootConfigToHashProto < Mapper
        include Util::HasLogger

        def initialize
          super(
            inputs: [
              Input.new(type: Vagrant::Config::V2::Root),
            ],
            output: SDK::Args::Hash,
            func: method(:converter),
          )
        end

        def converter(c)
          c.to_proto
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

          # Include a unique identifier for this configuration instance. This
          # will allow us to identifier it later when it is decoded.
          if !data.key?("_vagrant_config_identifier")
            data["_vagrant_config_identifier"] = SecureRandom.uuid
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
