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

        # @param [Symbol] name of the action to run
        def action(name, *args)
          d = Type::Direct.new(arguments: args)
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

        def machine_id_changed
          req = SDK::FuncSpec::Args.new(args: seed_protos)
          client.machine_id_changed(req)
        end

        # @return [SDK::SSHInfo] ssh info for machine
        def ssh_info
          req = SDK::FuncSpec::Args.new(args: seed_protos)
          client.ssh_info(req)
        end

         # @return [SDK::Args::Target::Machine::State] machine state
         def state
          req = SDK::FuncSpec::Args.new(args: seed_protos)
          client.state(req)
         end
      end
    end
  end
end
