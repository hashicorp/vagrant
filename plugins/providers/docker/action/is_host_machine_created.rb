module VagrantPlugins
  module DockerProvider
    module Action
      class IsHostMachineCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env[:machine].provider.host_vm?
            env[:result] = true
            return @app.call(env)
          end

          host_machine = env[:machine].provider.host_vm
          env[:result] =
            host_machine.state.id != Vagrant::MachineState::NOT_CREATED_ID

          # If the host machine isn't created, neither are we. It is
          # important we set this to nil here so that global-status
          # sees the right thing.
          env[:machine].id = nil if !env[:result]

          @app.call(env)
        end
      end
    end
  end
end
