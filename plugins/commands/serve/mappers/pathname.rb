# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class PathnameProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Path" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Path,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::Path.decode(fv.value.value)
        end
      end

      class PathnameToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Pathname)],
            output: SDK::Args::Path,
            func: method(:converter),
          )
        end

        def converter(path)
          SDK::Args::Path.new(path: path.to_s)
        end
      end

      class PathnameFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Path)],
            output: Pathname,
            func: method(:converter),
          )
        end

        def converter(path)
          Pathname.new(path.path)
        end
      end
    end
  end
end
