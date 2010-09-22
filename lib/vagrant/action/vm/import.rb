module Vagrant
  class Action
    module VM
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env.ui.info I18n.t("vagrant.actions.vm.import.importing", :name => env.env.box.name)

          # Import the virtual machine
          env.env.vm.vm = VirtualBox::VM.import(env.env.box.ovf_file.to_s) do |progress|
            env.ui.report_progress(progress.percent, 100, false)
          end

          # Flag as erroneous and return if import failed
          raise Errors::VMImportFailure.new if !env["vm"].vm

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if env["vm"].created?
            return if env["vagrant.error"].is_a?(Errors::VagrantError)

            # Interrupted, destroy the VM
            env["actions"].run(:destroy)
          end
        end
      end
    end
  end
end
