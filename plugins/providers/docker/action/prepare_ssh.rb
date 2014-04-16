module VagrantPlugins
  module DockerProvider
    module Action
      class PrepareSSH
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # If we aren't using a host VM, then don't worry about it
          return @app.call(env) if !env[:machine].provider.host_vm?

          # Get the container's SSH info
          info = env[:machine].ssh_info
          info[:port] ||= 22

          # Modify the SSH info to be the host VM's info
          env[:ssh_info] = env[:machine].provider.host_vm.ssh_info

          # Modify the SSH options for when we `vagrant ssh`...
          ssh_opts = env[:ssh_opts] || {}

          # Append "-t" to force a TTY allocation
          ssh_opts[:extra_args] = Array(ssh_opts[:extra_args])
          ssh_opts[:extra_args] << "-t"

          # Append our real SSH command
          ssh_opts[:extra_args] <<
            "ssh -i /home/vagrant/insecure " +
            "-p#{info[:port]} " +
            "#{info[:username]}@#{info[:host]}"

          # Set the opts
          env[:ssh_opts] = ssh_opts

          @app.call(env)
        end
      end
    end
  end
end
