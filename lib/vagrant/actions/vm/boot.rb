module Vagrant
  module Actions
    module VM
      class Boot < Base
        def prepare
          @runner.env.config.vm.share_folder("v-root", @runner.env.config.vm.project_directory, @runner.env.root_path)
        end

        def execute!
          @runner.invoke_around_callback(:boot) do
            # Startup the VM
            boot

            # Wait for it to complete booting, or error if we could
            # never detect it booted up successfully
            if !wait_for_boot
              error_and_exit(:vm_failed_to_boot)
            end
          end
        end

        def boot
          logger.info "Booting VM..."
          @runner.vm.start(@runner.env.config.vm.boot_mode)
        end

        def wait_for_boot(sleeptime=5)
          logger.info "Waiting for VM to boot..."

          @runner.env.config.ssh.max_tries.to_i.times do |i|
            logger.info "Trying to connect (attempt ##{i+1} of #{Vagrant.config[:ssh][:max_tries]})..."

            if @runner.env.ssh.up?
              logger.info "VM booted and ready for use!"
              return true
            end

            sleep sleeptime
          end

          logger.info "Failed to connect to VM! Failed to boot?"
          false
        end
      end
    end
  end
end
