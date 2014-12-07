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

          # Build the command we'll execute within the Docker host machine:
          ssh_command = env[:machine].communicate.container_ssh_command
          if !Array(ssh_opts[:extra_args]).empty?
            ssh_command << " #{Array(ssh_opts[:extra_args]).join(" ")}"
          end

          # Modify the SSH options for the original command:
          # Append "-t" to force a TTY allocation
          ssh_opts[:extra_args] = ["-t"]
          # Enable Agent forwarding when requested for the target VM
          if env[:machine].ssh_info[:forward_agent]
            ssh_opts[:extra_args] << "-o ForwardAgent=yes"
          end
          ssh_opts[:extra_args] << ssh_command

          # Set the opts
          env[:ssh_opts] = ssh_opts

          @app.call(env)
        end
      end
    end
  end
end
