# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
              arg.type == "hashicorp.vagrant.sdk.Args.Target.Machine" &&
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

      # Build a machine from a target
      class MachineFromTarget < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::Target)
          end
          super(inputs: inputs, output: Vagrant::Machine, func: method(:converter))
        end

        def converter(target)
          m = target.to_machine
          Vagrant::Machine.new(nil, nil, nil, nil, nil, nil, nil, nil, nil, base=false, client: m)
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
          Vagrant::Machine.new(client: machine)
        end
      end

      class MachineClientToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Client::Target::Machine)],
            output: SDK::Args::Target::Machine,
            func: method(:converter),
          )
        end

        def converter(m)
          m.to_proto
        end
      end

      class MachineStateFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Target::Machine::State)],
            output: Vagrant::MachineState,
            func: method(:converter),
          )
        end

        def converter(m)
          Vagrant::MachineState.new(
            m.id.to_sym, m.short_description, m.long_description
          )
        end
      end

      class MachineStateToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Vagrant::MachineState)],
            output: SDK::Args::Target::Machine::State,
            func: method(:converter),
          )
        end

        def converter(machine_state)
          SDK::Args::Target::Machine::State.new(
            id: machine_state.id,
            short_description: machine_state.short_description,
            long_description: machine_state.long_description,
          )
        end
      end

      class MachineToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Vagrant::Machine)],
            output: SDK::Args::Target::Machine,
            func: method(:converter),
          )
        end

        def converter(machine)
          machine.client.to_proto
        end
      end

    end
  end
end
