require "vagrant/util/busy"
require "vagrant/util/subprocess"

module VagrantPlugins
  module DockerProvider
    module Executor
      # The Local executor executes a Docker client that is running
      # locally.
      class Local
        def execute(*args, &block)
          opts = args.last.is_a?(Hash) ? args.pop : {}

          # Append in the options for subprocess
          cmd = args.dup
          cmd << { notify: [:stdout, :stderr] }

          interrupted  = false
          int_callback = ->{ interrupted = true }
          result = ::Vagrant::Util::Busy.busy(int_callback) do
            ::Vagrant::Util::Subprocess.execute(*cmd, &block)
          end

          result.stderr.gsub!("\r\n", "\n")
          result.stdout.gsub!("\r\n", "\n")

          if result.exit_code != 0 && !interrupted
            raise Errors::ExecuteError,
              command: cmd.inspect,
              stderr: result.stderr,
              stdout: result.stdout
          end

          result.stdout
        end
      end
    end
  end
end
