module Vagrant
  class Action
    module VM
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env.logger.info "Importing base VM (#{env.env.box.ovf_file})"

          begin
            # Import the virtual machine
            env.env.vm.vm = VirtualBox::VM.import(env.env.box.ovf_file) do |progress|
              env.logger.report_progress(progress.percent, 100, false)
            end

            # Flag as erroneous and return if import failed
            return env.error!(:virtualbox_import_failure) if !env['vm'].vm
          ensure
            env.logger.clear_progress
          end

          # Import completed successfully. Continue the chain
          @app.call(env)
        end
        
        def rescue(env)
          # Interrupted, destroy the VM
          env["actions"].run(:destroy)
        end
      end
    end
  end
end
