require "log4r"

require "vagrant/util/ssh"

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
          # Grab the SSH info from the machine
          info = env[:machine].ssh_info

          # If the result is nil, then the machine is telling us that it is
          # not yet ready for SSH, so we raise this exception.
          raise Errors::SSHNotReady if info.nil?

          if info[:private_key_path]
            # Check SSH key permissions
            info[:private_key_path].each do |path|
              SSH.check_key_permissions(Pathname.new(path))
            end
          end

          # Execute!
          command = env[:ssh_run_command]
          opts = env[:ssh_opts] || {}
          opts[:extra_args] = ["-t", command]
          opts[:subprocess] = true
          env[:ssh_run_exit_status] = Util::SSH.exec(info, opts)

          # Call the next middleware
          @app.call(env)
        end
      end
    end
  end
end
