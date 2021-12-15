require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class SyncedFolder
        prepend Util::ClientSetup
        prepend Util::HasLogger

        include CapabilityPlatform
        include Util::HasSeeds::Client

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
          folder_proto = folder_proto(folders)
          direct_any = direct_opts_proto(opts)

          req = SDK::FuncSpec::Args.new(
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                value: Google::Protobuf::Any.pack(machine),
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Folder",
                value: Google::Protobuf::Any.pack(folder_proto),
              ),
              SDK::FuncSpec::Value.new(
                name: "",
                type: "hashicorp.vagrant.sdk.Args.Direct",
                value: Google::Protobuf::Any.pack(direct_any),
              )
            ]
          )
          client.enable(req)
        end

        # @param [Sdk::Args::Machine]
        def disable(machine, folders, opts)
          folders_proto = folder_proto(folders)
          direct_any = direct_opts_proto(opts)

          req = SDK::FuncSpec::Args.new(
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                value: Google::Protobuf::Any.pack(machine),
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Folder",
                value: Google::Protobuf::Any.pack(folders_proto),
              ),
              SDK::FuncSpec::Value.new(
                name: "",
                type: "hashicorp.vagrant.sdk.Args.Direct",
                value: Google::Protobuf::Any.pack(direct_any),
              )
            ]
          )
          client.disable(req)
        end

        # @param [Sdk::Args::Machine]
        def cleanup(machine, opts)
          direct_any = direct_opts_proto(opts)

          req = SDK::FuncSpec::Args.new(
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                value: Google::Protobuf::Any.pack(machine),
              ),
              SDK::FuncSpec::Value.new(
                name: "",
                type: "hashicorp.vagrant.sdk.Args.Direct",
                value: Google::Protobuf::Any.pack(direct_any),
              )
            ]
          )
          client.cleanup(req)
        end

        private

        def folder_proto(folders)
          folders_proto = {}
          folders.each do |k, v| 
            folder_proto[k] =  mapper.map(v, to: Google::Protobuf::Any)
          end
          folders_proto
        end

        def direct_opts_proto(opts)
          direct_proto = Types::Direct.new(arguments: opts)
          mapper.map(direct_proto, to: Google::Protobuf::Any)
        end
      end
    end
  end
end
