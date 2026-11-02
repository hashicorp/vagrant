# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class FoldersProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Folders" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Folders,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::Folders.decode(fv.value.value)
        end
      end

      class FoldersFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::Folders),
              Input.new(type: Mappers),
            ],
            output: Type::Folders,
            func: method(:converter)
          )
        end

        def converter(proto, mappers)
          h = mappers.map(proto.folders, to: Hash)
          Type::Folders.new(value: h)
        end
      end

      class FoldersToProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Type::Folders),
              Input.new(type: Mappers),
            ],
            output: SDK::Args::Folders,
            func: method(:converter),
          )
        end

        def converter(opts, mappers)
          h = mappers.map(opts.value.to_h, to: SDK::Args::Hash)
          SDK::Args::Folders.new(folders: h)
        end
      end
    end
  end
end
