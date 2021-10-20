require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class SyncedFolder
        include CapabilityPlatform

        prepend Util::ClientSetup
        prepend Util::HasLogger

        # @param [Sdk::Args::Machine]
        # @return [Boolean]
        def usable(machine)
          req = SDK::FuncSpec::Args.new(
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                value: Google::Protobuf::Any.pack(machine),
              )
            ]
          )
          res = client.usable(req)
          res.usable
        end

        # @param [Sdk::Args::Machine]
        def enable(machine, folders, opts)
        end

        # @param [Sdk::Args::Machine]
        def disable(machine, folders, opts)
        end

        # @param [Sdk::Args::Machine]
        def cleanup(machine, opts)
        end
      end
    end
  end
end
