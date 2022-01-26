require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class Provider
        prepend Util::ClientSetup
        prepend Util::HasLogger

        include CapabilityPlatform
        include Util::HasSeeds::Client

        # @return [Boolean] is the provider usable
        def usable?
          req = SDK::FuncSpec::Args.new(
            args: []
          )
          res = client.usable(req)
          res.is_usable
        end

        # @return [Boolean] is the provider installed
        def installed?
          req = SDK::FuncSpec::Args.new(
            args: []
          )
          res = client.installed(req)
          res.is_installed
        end

        # @param [Sdk::Args::Machine]
        # @param [Symbol] name of the action to run
        def action(machine, name)
          arg_protos = seed_protos
          d = Type::Direct.new(arguments: [machine])
          da = mapper.map(d, to: Google::Protobuf::Any)
          arg_protos << SDK::FuncSpec::Value.new(
            name: "",
            type: "hashicorp.vagrant.sdk.Args.Direct",
            value: Google::Protobuf::Any.pack(da),
          )
          req = SDK::Provider::ActionRequest.new(
            name: name.to_s,
            func_args: SDK::FuncSpec::Args.new(
              args: arg_protos,
            )
          )
          client.action(req)
        end

        # @param [Sdk::Args::Machine]
        def machine_id_changed(machine)
          args = seed_protos
          args << SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target.Machine",
              value: Google::Protobuf::Any.pack(machine),
          )
          req = SDK::FuncSpec::Args.new(args: args)
          client.machine_id_changed(req)
        end

        # @param [Sdk::Args::Machine]
        # @return [Hash] ssh info for machine
        def ssh_info(machine)
          args = seed_protos
          args << SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target.Machine",
              value: Google::Protobuf::Any.pack(machine),
          )
          req = SDK::FuncSpec::Args.new(args: args)
          machine_ssh_info = client.ssh_info(req)
          machine_ssh_info.to_h
        end

        # @param [Sdk::Args::Machine]
        # @return [Vagrant::MachineState] machine state
        def state(machine)
          args = seed_protos
          args << SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target.Machine",
              value: Google::Protobuf::Any.pack(machine),
          )
          req = SDK::FuncSpec::Args.new(args: args)
          machine_state = client.state(req)
          mapper.map(machine_state, to: Vagrant::MachineState)
        end
      end
    end
  end
end
