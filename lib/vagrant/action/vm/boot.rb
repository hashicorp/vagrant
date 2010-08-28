module Vagrant
  class Action
    module VM
      class Boot
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          # Do nothing if the environment is erroneous
          return if env.error?

          @env = env

          # Start up the VM and wait for it to boot.
          boot
          return env.error!(:vm_failed_to_boot) if !wait_for_boot
          return if env.error?

          @app.call(env)
        end

        def boot
          @env.ui.info "vagrant.actions.vm.boot.booting"
          @env["vm"].vm.start(@env.env.config.vm.boot_mode)
        end

        def wait_for_boot
          @env.ui.info "vagrant.actions.vm.boot.waiting"

          @env.env.config.ssh.max_tries.to_i.times do |i|
            if @env["vm"].ssh.up?
              @env.ui.info "vagrant.actions.vm.boot.ready"
              return true
            end

            # Return true so that the vm_failed_to_boot error doesn't
            # get shown
            return true if @env.interrupted?

            sleep 5 if !@env["vagrant.test"]
          end

          @env.ui.error "vagrant.actions.vm.boot.failed"
          false
        end
      end
    end
  end
end

