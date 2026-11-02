# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class TerminalProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.TerminalUI" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::TerminalUI,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::TerminalUI.decode(fv.value.value)
        end
      end

      # Build a terminal client from a FuncSpec value
      class TerminalFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.TerminalUI" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Terminal, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Terminal.load(proto.value.value, broker: broker)
        end
      end

      # Build a terminal client from a proto instance
      class TerminalFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::TerminalUI)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Terminal, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Terminal.load(proto, broker: broker)
        end
      end

      class TerminalFromProject < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Client::Project)],
            output: Client::Terminal,
            func: method(:converter)
          )
        end

        def converter(project)
          project.ui
        end
      end

      class TerminalToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Client::Terminal)],
            output: SDK::Args::TerminalUI,
            func: method(:converter),
          )
        end

        def converter(terminal)
          terminal.to_proto
        end
      end
    end
  end
end
