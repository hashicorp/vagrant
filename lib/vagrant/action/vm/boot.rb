module Vagrant
  module Action
    module VM
      class Boot
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          # Start up the VM and wait for it to boot.
          boot
          raise Errors::VMFailedToBoot if !wait_for_boot

          @app.call(env)
        end

        def boot
          @env[:ui].info I18n.t("vagrant.actions.vm.boot.booting")
          @env[:vm].driver.start(@env[:vm].config.vm.boot_mode)
        end

        def wait_for_boot
          @env[:ui].info I18n.t("vagrant.actions.vm.boot.waiting")

          @env[:vm].config.ssh.max_tries.to_i.times do |i|
            if @env[:vm].channel.ready?
              @env[:ui].info I18n.t("vagrant.actions.vm.boot.ready")
              return true
            end

            # Return true so that the vm_failed_to_boot error doesn't
            # get shown
            return true if @env[:interrupted]

            sleep 2 if !@env["vagrant.test"]
          end

          @env[:ui].error I18n.t("vagrant.actions.vm.boot.failed")
          false
        end
      end
    end
  end
end

