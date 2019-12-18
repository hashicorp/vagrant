require "log4r"

require "vagrant/util/platform"
require "vagrant/util/ssh"
require "vagrant/util/shell_quote"

module Vagrant
  module Action
    module Builtin
      # This class will run a single command on the remote machine and will
      # mirror the output to the UI. The resulting exit status of the command
      # will exist in the `:ssh_run_exit_status` key in the environment.
      class SSHRun
        # For quick access to the `SSH` class.
        include Vagrant::Util

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::ssh_run")
        end

        def call(env)
          # Grab the SSH info from the machine or the environment
          info = env[:ssh_info]
          info ||= env[:machine].ssh_info

          # If the result is nil, then the machine is telling us that it is
          # not yet ready for SSH, so we raise this exception.
          raise Errors::SSHNotReady if info.nil?

          info[:private_key_path] ||= []

          if info[:keys_only] && info[:private_key_path].empty?
            raise Errors::SSHRunRequiresKeys
          end

          # Get the command and wrap it in a login shell
          command = ShellQuote.escape(env[:ssh_run_command], "'")

          if env[:machine].config.vm.communicator == :winssh
            shell = env[:machine].config.winssh.shell
          else
            shell = env[:machine].config.ssh.shell
          end

          if shell == "cmd"
            # Add an extra space to the command so cmd.exe quoting works
            # properly
            command = "#{shell} /C #{command} "
          elsif shell == "powershell"
            command = "$ProgressPreference = \"SilentlyContinue\"; #{command}"
            command = Base64.strict_encode64(command.encode("UTF-16LE", "UTF-8"))
            command = "#{shell} -encodedCommand #{command}"
          else
            command = "#{shell} -c '#{command}'"
          end

          # Execute!
          opts = env[:ssh_opts] || {}
          opts[:extra_args] ||= []

          # Allow the user to specify a tty or non-tty manually, but if they
          # don't then we default to a TTY unless they are using WinSSH
          if !opts[:extra_args].include?("-t") &&
              !opts[:extra_args].include?("-T") &&
              env[:tty] &&
              env[:machine].config.vm.communicator != :winssh
            opts[:extra_args] << "-t"
          end

          opts[:extra_args] << command
          opts[:subprocess] = true
          env[:ssh_run_exit_status] = Util::SSH.exec(info, opts)

          # Call the next middleware
          @app.call(env)
        end
      end
    end
  end
end
