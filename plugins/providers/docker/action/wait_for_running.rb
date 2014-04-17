require "thread"

require "log4r"

module VagrantPlugins
  module DockerProvider
    module Action
      class WaitForRunning
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::docker::waitforrunning")
        end

        def call(env)
          machine = env[:machine]

          wait = true
          if !machine.provider_config.remains_running
            wait = false
          elsif machine.provider.state.id == :running
            wait = false
          end

          # If we're not waiting, just return
          return @app.call(env) if !wait

          machine.ui.output(I18n.t("docker_provider.waiting_for_running"))

          # First, make sure it leaves the stopped state if its supposed to.
          after = sleeper(5)
          while machine.provider.state.id == :stopped
            if after[:done]
              raise Errors::StateStopped
            end
            sleep 0.2
          end

          # Then, wait for it to become running
          after = sleeper(30)
          while true
            state = machine.provider.state
            break if state.id == :running
            @logger.info("Waiting for container to run. State: #{state.id}")

            if after[:done]
              raise Errors::StateNotRunning
            end

            sleep 0.2
          end

          @app.call(env)
        end

        protected

        def sleeper(duration)
          Thread.new(duration) do |d|
            sleep(d)
            Thread.current[:done] = true
          end
        end
      end
    end
  end
end
