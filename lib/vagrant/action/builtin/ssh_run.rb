require "log4r"

module Vagrant
  module Action
    module Builtin
      # This class will run a single command on the remote machine and will
      # mirror the output to the UI. The resulting exit status of the command
      # will exist in the `:ssh_run_exit_status` key in the environment.
      class SSHRun
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::ssh_run")
        end

        def call(env)
          command = env[:ssh_run_command]

          @logger.debug("Executing command: #{command}")
          exit_status = 0
          exit_status = env[:machine].communicate.execute(command, :error_check => false) do |type, data|
            # Determine the proper channel to send the output onto depending
            # on the type of data we are receiving.
            channel = type == :stdout ? :out : :error

            # Print the output as it comes in, but don't prefix it and don't
            # force a new line so that the output is properly preserved however
            # it may be formatted.
            env[:ui].info(data.to_s,
                          :prefix => false,
                          :new_line => false,
                          :channel => channel)
          end

          # Set the exit status on a known environmental variable
          env[:ssh_run_exit_status] = exit_status

          # Call the next middleware
          @app.call(env)
        end
      end
    end
  end
end
