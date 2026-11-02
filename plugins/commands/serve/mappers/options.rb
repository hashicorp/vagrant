# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class OptionsProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Options" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Options,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::Options.decode(fv.value.value)
        end
      end

      class OptionsFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::Options),
              Input.new(type: Mappers),
            ],
            output: Type::Options,
            func: method(:converter)
          )
        end

        def converter(proto, mappers)
          h = mappers.map(proto.options, to: Hash)
          Type::Options.new(value: h)
        end
      end

      class OptionsToProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Type::Options),
              Input.new(type: Mappers),
            ],
            output: SDK::Args::Options,
            func: method(:converter),
          )
        end

        def converter(opts, mappers)
          h = mappers.map(opts.value.to_h, to: SDK::Args::Hash)
          SDK::Args::Options.new(options: h)
        end
      end

    end
  end
end
