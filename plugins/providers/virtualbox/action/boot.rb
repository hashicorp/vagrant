module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Boot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          boot_mode = @env[:machine].provider_config.gui ? "gui" : "headless"

          # Start up the VM and wait for it to boot.
          env[:ui].info I18n.t("vagrant.actions.vm.boot.booting")
          env[:machine].provider.driver.start(boot_mode)
          raise Errors::VMFailedToBoot if !wait_for_boot

          @app.call(env)
        end

        def wait_for_boot
          @env[:ui].info I18n.t("vagrant.actions.vm.boot.waiting")

          @env[:machine].config.ssh.max_tries.to_i.times do |i|
            if @env[:machine].communicate.ready?
              @env[:ui].info I18n.t("vagrant.actions.vm.boot.ready")
              return true
            end

            # Return true so that the vm_failed_to_boot error doesn't
            # get shown
            return true if @env[:interrupted]

            # If the VM is not starting or running, something went wrong
            # and we need to show a useful error.
            state = @env[:machine].provider.state.id
            raise Errors::VMFailedToRun if state != :starting && state != :running

            sleep 2 if !@env["vagrant.test"]
          end

          @env[:ui].error I18n.t("vagrant.actions.vm.boot.failed")
          false
        end
      end
    end
  end
end
