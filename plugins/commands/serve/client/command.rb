# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class Command < Client
        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def command_info_func
          spec = client.command_info_spec(Empty.new)
          cb = proc do |args|
            v = client.command_info(args)
            mapper.map(v, to: Type::CommandInfo)
          end
          [spec, cb]
        end

        # Get command information
        #
        # @return [Type::CommandInfo]
        def command_info
          run_func
        end

        # Generate callback and spec for required arguments
        #
        # @param args [Array<String>] Command to execute
        # @return [SDK::FuncSpec, Proc]
        def execute_func(args=[])
          spec = client.execute_spec(
            SDK::Command::ExecuteSpecReq.new(
              command_args: args
            )
          )

          cb = proc do |execute_args, funcspec_args|
            req = SDK::Command::ExecuteReq.new(
              command_args: execute_args,
              spec: funcspec_args,
            )
            result = client.execute(req)
            result.exit_code.to_i
          end
          [spec, cb]
        end

        # Execute command
        #
        # @param args [Array<String>] Command to execute
        # @return [Integer] exit code
        def execute(args=[])
          spec, cb = execute_func(args)
          cb.call(args, generate_funcspec_args(spec))
        end
      end
    end
  end
end
