require "log4r"

module VagrantPlugins
  module DockerProvider
    module Action
      # This action is responsible for creating the host machine if
      # we need to. The host machine is where Docker containers will
      # live.
      class HostMachine
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::docker::hostmachine")
        end

        def call(env)
          if !env[:machine].provider.host_vm?
            @logger.info("No host machine needed.")
            return @app.call(env)
          end

          env[:machine].ui.output(I18n.t(
            "docker_provider.host_machine_needed"))

          host_machine = env[:machine].provider.host_vm

          begin
            env[:machine].provider.host_vm_lock do
              setup_host_machine(host_machine, env)
            end
          rescue Vagrant::Errors::EnvironmentLockedError
            sleep 1
            retry
          end

          @app.call(env)
        end

        protected

        def setup_host_machine(host_machine, env)
          # Create a UI for this machine that stays at the detail level
          proxy_ui = host_machine.ui.dup
          proxy_ui.opts[:bold] = false
          proxy_ui.opts[:prefix_spaces] = true
          proxy_ui.opts[:target] = env[:machine].name.to_s

          # Reload the machine so that if it was created while we didn't
          # hold the lock, we'll see the updated state.
          host_machine.reload

          # See if the machine is ready already. If not, start it.
          if host_machine.communicate.ready?
            env[:machine].ui.detail(I18n.t("docker_provider.host_machine_ready"))
          else
            env[:machine].ui.detail(
              I18n.t("docker_provider.host_machine_starting"))
            env[:machine].ui.detail(" ")
            host_machine.with_ui(proxy_ui) do
              host_machine.action(:up)
            end

            # Verify communication is ready. If not, we have a problem.
            if !host_machine.communicate.ready?
              raise Errors::HostVMCommunicatorNotReady,
                id: host_machine.id
            end
          end
        end
      end
    end
  end
end
