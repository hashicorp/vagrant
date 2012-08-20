module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Halt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          current_state = env[:machine].provider.state
          if current_state == :running || current_state == :gurumeditation
            # If the VM is running and we're not forcing, we can
            # attempt a graceful shutdown
            if current_state == :running && !env[:force]
              env[:ui].info I18n.t("vagrant.actions.vm.halt.graceful")
              env[:machine].guest.halt
            end

            # If we're not powered off now, then force it
            if env[:machine].provider.state != :poweroff
              env[:ui].info I18n.t("vagrant.actions.vm.halt.force")
              env[:machine].provider.driver.halt
            end

            # Sleep for a second to verify that the VM properly
            # cleans itself up
            sleep 1 if !env["vagrant.test"]
          end

          @app.call(env)
        end
      end
    end
  end
end
