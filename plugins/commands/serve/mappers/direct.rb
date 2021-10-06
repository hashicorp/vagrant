require "google/protobuf/well_known_types"
require "google/protobuf/wrappers_pb"

module VagrantPlugins
  module CommandServe
    class Mappers
      class Direct < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Direct" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Mappers)
          end
          super(inputs: inputs, output: Array, func: method(:converter))
        end

        def converter(proto, mappers)
          SDK::Args::Direct.decode(proto.value.value).list.map do |v|
            namespace = v.type_name.split(".")
            klass_name = namespace.pop

            ns = namespace.inject(Object) { |memo, n|
              memo.const_get(n.split("_").map(&:capitalize).join.to_sym) if memo
            }
            klass = ns.const_get(klass_name) if ns
            v = v.unpack(klass) if klass

            new_v = true
            while new_v
              begin
                v = mappers.map(v)
              rescue
                new_v = false
              end
            end
            v
          end
        end
      end
    end
  end
end
