module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:clone_id]
            clone(env)
          else
            import(env)
          end
        end

        def clone(env)
          # Do the actual clone
          env[:ui].info I18n.t("vagrant.actions.vm.clone.creating")
          env[:machine].id = env[:machine].provider.driver.clonevm(
            env[:clone_id], env[:clone_snapshot]) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't
          # disappear immediately.
          env[:ui].clear_line

          # Flag as erroneous and return if clone failed
          raise Vagrant::Errors::VMCloneFailure if !env[:machine].id

          # Copy the SSH key from the clone machine if we can
          if env[:clone_machine]
            key_path = env[:clone_machine].data_dir.join("private_key")
            if key_path.file?
              FileUtils.cp(
                key_path,
                env[:machine].data_dir.join("private_key"))
            end
          end

          # Continue
          @app.call(env)
        end

        def import(env)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               name: env[:machine].box.name)

          # Import the virtual machine
          ovf_file = env[:machine].box.directory.join("box.ovf").to_s
          id = env[:machine].provider.driver.import(ovf_file) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Set the machine ID
          env[:machine_id] = id
          env[:machine].id = id if !env[:skip_machine]

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Flag as erroneous and return if import failed
          raise Vagrant::Errors::VMImportFailure if !id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if env[:machine] && env[:machine].state.id != :not_created
            return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

            # If we're not supposed to destroy on error then just return
            return if !env[:destroy_on_error]

            # Interrupted, destroy the VM. We note that we don't want to
            # validate the configuration here, and we don't want to confirm
            # we want to destroy.
            destroy_env = env.clone
            destroy_env[:config_validate] = false
            destroy_env[:force_confirm_destroy] = true
            env[:action_runner].run(Action.action_destroy, destroy_env)
          end
        end
      end
    end
  end
end
