require "log4r"

require "vagrant/util/platform"
require "vagrant/util/silence_warnings"

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

          # TODO(mitchellh): process-level lock so that we don't
          # step on parallel Vagrant's toes.

          host_machine = env[:machine].provider.host_vm

          # See if the machine is ready already.
          if host_machine.communicate.ready?
            env[:machine].ui.detail(I18n.t("docker_provider.host_machine_ready"))
            return @app.call(env)
          end

          # Create a UI for this machine that stays at the detail level
          proxy_ui = host_machine.ui.dup
          proxy_ui.opts[:bold] = false
          proxy_ui.opts[:prefix_spaces] = true
          proxy_ui.opts[:target] = env[:machine].name.to_s

          env[:machine].ui.detail(
            I18n.t("docker_provider.host_machine_starting"))
          env[:machine].ui.detail(" ")
          host_machine.with_ui(proxy_ui) do
            host_machine.action(:up)
          end

          @app.call(env)
        end
      end
    end
  end
end
