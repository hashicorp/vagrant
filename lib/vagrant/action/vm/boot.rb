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
          @env.logger.info "Booting VM..."
          @env["vm"].vm.start(@env.env.config.vm.boot_mode)
        end

        def wait_for_boot
          @env.logger.info "Waiting for VM to boot..."

          @env.env.config.ssh.max_tries.to_i.times do |i|
            @env.logger.info "Trying to connect (attempt ##{i+1} of #{@env.env.config[:ssh][:max_tries]})..."

            if @env["vm"].ssh.up?
              @env.logger.info "VM booted and ready for use!"
              return true
            end

            # Return true so that the vm_failed_to_boot error doesn't
            # get shown
            return true if @env.interrupted?

            sleep 5 if !@env["vagrant.test"]
          end

          @env.logger.info "Failed to connect to VM! Failed to boot?"
          false
        end
      end
    end
  end
end

