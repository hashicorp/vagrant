require "ostruct"

module VagrantPlugins
  module CommandServe
    module Client
      class Command
        prepend Util::ClientSetup
        prepend Util::HasLogger

        include Util::HasSeeds::Client

        def command_info
          result = client.command_info(
            SDK::FuncSpec::Args.new(args: seed_protos)
          )

          OpenStruct.new(result.command_info.to_hash)
        end

        def execute(args=[])
          result = client.execute(
            SDK::Command::ExecuteReq.new(
              command_args: args,
              spec: SDK::FuncSpec::Args.new(
                args: seed_protos,
              ),
            )
          )

          result.exit_code.to_i
        end
      end
    end
  end
end
