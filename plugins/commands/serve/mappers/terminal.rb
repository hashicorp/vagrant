module VagrantPlugins
  module CommandServe
    class Mappers
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

      # Build a terminal client from a serialized proto string
      class TerminalFromString < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: String)
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
    end
  end
end
