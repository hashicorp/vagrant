require "pathname"

require "vagrant/util/scp"

module Vagrant
  module Action
    module Builtin
      # This class will run a single file upload/download to/from the remote
      # machine.
      #
      # The exit code will be made available in the env variable with the key:
      # `:scp_run_exit_status`
      class SCPExec
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          # Grab the SSH info from the machine
          info = env[:machine].ssh_info

          # If the result is nil, then the machine is telling us that it is
          # not yet ready for SSH, so we raise this exception.
          raise Errors::SSHNotReady if info.nil?

          info[:private_key_path] ||= []

          if info[:private_key_path].empty? && info[:password]
            env[:ui].warn(I18n.t("vagrant.ssh_exec_password"))
          end

          # Exec!
          Vagrant::Util::SCP.exec(info, env)
        end
      end
    end
  end
end
