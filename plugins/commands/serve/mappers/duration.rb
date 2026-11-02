# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class DurationProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.TimeDuration" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::TimeDuration,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::TimeDuration.decode(fv.value.value)
        end
      end

      class DurationFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::TimeDuration)],
            output: Type::Duration,
            func: method(:converter),
          )
        end

        def converter(proto)
          Type::Duration.new(value: proto.duration)
        end
      end

      class DurationToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Type::Duration)],
            output: SDK::Args::TimeDuration,
            func: method(:converter),
          )
        end

        def converter(duration)
          SDK::Args::TimeDuration.new(duration: duration.value)
        end
      end
    end
  end
end
