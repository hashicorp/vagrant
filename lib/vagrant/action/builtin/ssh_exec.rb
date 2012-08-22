require "vagrant/util/ssh"

module Vagrant
  module Action
    module Builtin
      # This class will exec into a full fledged SSH console into the
      # remote machine. This middleware assumes that the VM is running and
      # ready for SSH, and uses the {Machine#ssh_info} method to retrieve
      # SSH information necessary to connect.
      #
      # Note: If there are any middleware after `SSHExec`, they will **not**
      # run, since exec replaces the currently running process.
      class SSHExec
        # For quick access to the `SSH` class.
        include Vagrant::Util

        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Grab the SSH info from the machine
          info = env[:machine].ssh_info

          # If the result is nil, then the machine is telling us that it is
          # not yet ready for SSH, so we raise this exception.
          raise Errors::SSHNotReady if info.nil?

          # Check the SSH key permissions
          SSH.check_key_permissions(info[:private_key_path])

          # Exec!
          SSH.exec(info, env[:ssh_opts])
        end
      end
    end
  end
end
