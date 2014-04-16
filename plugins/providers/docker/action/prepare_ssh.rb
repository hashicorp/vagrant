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

          env[:machine].ui.output(I18n.t(
            "docker_provider.ssh_through_host_vm"))

          # Modify the SSH info to be the host VM's info
          env[:ssh_info] = env[:machine].provider.host_vm.ssh_info

          # Modify the SSH options for when we `vagrant ssh`...
          ssh_opts = env[:ssh_opts] || {}

          # Append "-t" to force a TTY allocation
          ssh_opts[:extra_args] = Array(ssh_opts[:extra_args])
          ssh_opts[:extra_args] << "-t"

          # Append our real SSH command. If we have a host VM we know
          # we're using our special communicator, so we can call helpers there
          ssh_opts[:extra_args] <<
           env[:machine].communicate.container_ssh_command

          # Set the opts
          env[:ssh_opts] = ssh_opts

          @app.call(env)
        end
      end
    end
  end
end
