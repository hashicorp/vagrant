module Vagrant
  module Action
    module VM
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing", :name => env[:vm].box.name)

          # Import the virtual machine
          env[:vm].vm = VirtualBox::VM.import(env[:vm].box.directory.join("box.ovf").to_s) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress.percent, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line

          # Flag as erroneous and return if import failed
          raise Errors::VMImportFailure if !env[:vm].vm

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if env[:vm].created?
            return if env["vagrant.error"].is_a?(Errors::VagrantError)

            # Interrupted, destroy the VM. We note that we don't want to
            # validate the configuration here.
            destroy_env = env.clone
            destroy_env[:validate] = false
            env[:action_runner].run(:destroy, destroy_env)
          end
        end
      end
    end
  end
end
