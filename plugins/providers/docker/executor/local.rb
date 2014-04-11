require "vagrant/util/busy"
require "vagrant/util/subprocess"

module VagrantPlugins
  module DockerProvider
    module Executor
      # The Local executor executes a Docker client that is running
      # locally.
      class Local
        def execute(*cmd, &block)
          # Append in the options for subprocess
          cmd << { :notify => [:stdout, :stderr] }

          interrupted  = false
          int_callback = ->{ interrupted = true }
          result = Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(*cmd, &block)
          end

          if result.exit_code != 0 && !interrupted
            msg = result.stdout.gsub("\r\n", "\n")
            msg << result.stderr.gsub("\r\n", "\n")
            raise "#{cmd.inspect}\n#{msg}" #Errors::ExecuteError, :command => command.inspect
          end

          # Return the output, making sure to replace any Windows-style
          # newlines with Unix-style.
          result.stdout.gsub("\r\n", "\n")
        end
      end
    end
  end
end
