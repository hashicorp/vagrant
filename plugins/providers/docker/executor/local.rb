require "vagrant/util/busy"
require "vagrant/util/subprocess"

module VagrantPlugins
  module DockerProvider
    module Executor
      # The Local executor executes a Docker client that is running
      # locally.
      class Local
        def execute(*cmd, **opts, &block)
          # Append in the options for subprocess
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

          # If the new buildkit-based docker build is used, stdout is empty, and the output is in stderr
          if result.stdout.to_s.strip.length == 0
            result.stderr
          else
            result.stdout
          end
        end

        def windows?
          ::Vagrant::Util::Platform.windows? || ::Vagrant::Util::Platform.wsl?
        end
      end
    end
  end
end
