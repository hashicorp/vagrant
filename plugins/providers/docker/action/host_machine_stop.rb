require "log4r"

module VagrantPlugins
  module DockerProvider
    module Action
      # This action is responsible for creating the host machine if
      # we need to. The host machine is where Docker containers will
      # live.
      class HostMachineStop
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::docker::hostmachine")
        end

        def call(env)
          host_machine = env[:machine].provider.host_vm

          begin
            env[:machine].provider.host_vm_lock do
              stop_host_machine(host_machine, env)
            end
          rescue Vagrant::Errors::EnvironmentLockedError
            sleep 1
            retry
          end

          @app.call(env)
        end

        protected

        def stop_host_machine(host_machine, env)
          # Create a UI for this machine that stays at the detail level
          proxy_ui = host_machine.ui.dup
          proxy_ui.opts[:bold] = false
          proxy_ui.opts[:prefix_spaces] = true
          proxy_ui.opts[:target] = env[:machine].name.to_s

          # Reload the machine so that if it was created while we didn't
          # hold the lock, we'll see the updated state.
          host_machine.reload

          # If the machine is running, then we can stop it.
          if host_machine.communicate.ready?
            env[:machine].ui.detail(
              I18n.t("docker_provider.host_machine_stopping"))
            env[:machine].ui.detail(" ")
            host_machine.with_ui(proxy_ui) do
              host_machine.action(:halt)
            end

            # If we can still communicate with the machine, we have a problem.
            if host_machine.communicate.ready?
              raise Errors::HostVMCommunicatorNotHalted,
                id: host_machine.id
            end
          end
        end
      end
    end
  end
end
