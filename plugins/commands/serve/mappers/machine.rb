module VagrantPlugins
  module CommandServe
    class Mappers
      class MachineProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Target.Machine" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Target::Machine,
            func: method(:converter)
          )
        end

        def converter(fv)
          SDK::Args::Target::Machine.decode(fv.value.value)
        end
      end

      # Build a machine client from a FuncSpec value
      class MachineFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Machine" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target::Machine, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target::Machine.load(proto.value.value, broker: broker)
        end
      end

      # Build a machine client from a proto instance
      class MachineFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Target::Machine)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target::Machine, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target::Machine.load(proto, broker: broker)
        end
      end

      # Build a machine client from a serialized proto string
      class MachineFromString < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: String)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Target::Machine, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Target::Machine.load(proto, broker: broker)
        end
      end

      # Build a machine from a target
      class MachineFromTarget < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::Target)
            i << Input.new(type: Vagrant::Environment)
          end
          super(inputs: inputs, output: Vagrant::Machine, func: method(:converter))
        end

        def converter(target, env)
          env.machine(
            target.name.to_sym,
            target.provider_name.to_sym,
          )
        end
      end

      # Build a machine from a machine client
      class MachineFromMachineClient < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::Target::Machine)
            i << Input.new(type: Mappers)
          end
          super(inputs: inputs, output: Vagrant::Machine, func: method(:converter))
        end

        def converter(machine, mappers)
          env = mappers.map(machine.project, to: Vagrant::Environment)
          env.machine(
            machine.name.to_sym,
            machine.provider_name.to_sym,
          )
        end
      end

      class MachineToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type:Client::Target::Machine)],
            output: SDK::Args::Target::Machine,
            func: method(:converter),
          )
        end

        def converter(m)
          m.to_proto
        end
      end
    end
  end
end
