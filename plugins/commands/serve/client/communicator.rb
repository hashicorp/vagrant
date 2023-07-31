# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


module VagrantPlugins
  module CommandServe
    class Client
      class Communicator < Client
        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def ready_func
          spec = client.ready_spec(Empty.new)
          cb = proc do |args|
            client.ready(args).ready
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @return [bool]
        def ready(machine)
          run_func(machine)
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def wait_for_ready_func
          spec = client.wait_for_ready_spec(Empty.new)
          cb = proc do |args|
            client.wait_for_ready(args).ready
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @param [Integer] duration Timeout in seconds.
        # @return [Boolean]
        def wait_for_ready(machine, time)
          run_func(machine, Type::Duration.new(value: time))
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def download_func
          spec = client.download_spec(Empty.new)
          cb = proc do |args|
            client.download(args)
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @param [String] remote path
        # @param [String] local path
        def download(machine, from, to)
          from = Pathname.new(from.to_s) if !from.is_a?(Pathname)
          to = Pathname.new(to.to_s) if !to.is_a?(Pathname)

          run_func(
            Type::NamedArgument.new(name: "to", value: to),
            Type::NamedArgument.new(name: "from", value: from),
            machine
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def upload_func
          spec = client.upload_spec(Empty.new)
          cb = proc do |args|
            client.upload(args)
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @param [String] local path
        # @param [String] remote path
        def upload(machine, from, to)
          from = Pathname.new(from.to_s) if !from.is_a?(Pathname)
          to = Pathname.new(to.to_s) if !to.is_a?(Pathname)

          run_func(
            Type::NamedArgument.new(name: "source", value: from),
            Type::NamedArgument.new(name: "destination", value: to),
            machine
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def execute_func
          spec = client.execute_spec(Empty.new)
          cb = proc do |args|
            client.execute(args)
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @param [String] command to run
        # @param [Hash] options
        # @return [Integer]
        def execute(machine, cmd, opts)
          opts = {} if opts.nil?
          run_func(machine,
            Type::Options.new(value: opts),
            Type::CommunicatorCommandArguments.new(value: cmd)
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def privileged_execute_func
          spec = client.privileged_execute_spec(Empty.new)
          cb = proc do |args|
            client.privileged_execute(args)
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @param [String] command to run
        # @param [Hash] options
        # @return [Integer]
        def privileged_execute(machine, cmd, opts)
          opts = {} if opts.nil?
          run_func(machine,
            Type::Options.new(value: opts),
            Type::CommunicatorCommandArguments.new(value: cmd)
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def test_func
          spec = client.test_spec(Empty.new)
          cb = proc do |args|
            client.test(args).valid
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @param [String] command to run
        # @param [Hash] options
        # @return [Boolean]
        def test(machine, cmd, opts)
          opts = {} if opts.nil?
          run_func(machine,
            Type::Options.new(value: opts),
            Type::CommunicatorCommandArguments.new(value: cmd)
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def reset_func
          spec = client.reset_spec(Empty.new)
          cb = proc do |args|
            client.reset(args)
          end
          [spec, cb]
        end

        # Reset the communicator connection
        #
        # @param machine [Vagrant::Machine] Guest to reset connection on
        def reset(machine)
          run_func(machine)
        end
      end
    end
  end
end
