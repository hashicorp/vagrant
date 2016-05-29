require "log4r"

require "digest/md5"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ImportMaster
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::create_master")
        end

        def call(env)
          # If we don't have a box, nothing to do
          if !env[:machine].box
            return @app.call(env)
          end

          # Do the import while locked so that nobody else imports
          # a master at the same time. This is a no-op if we already
          # have a master that exists.
          lock_key = Digest::MD5.hexdigest(env[:machine].box.name)
          env[:machine].env.lock(lock_key, retry: true) do
            import_master(env)
          end

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          if env[:interrupted]
            @logger.info("Import of master VM was interrupted -> exiting.")
            return
          end

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        protected

        def import_master(env)
          master_id_file = env[:machine].box.directory.join("master_id")

          # Read the master ID if we have it in the file.
          env[:clone_id] = master_id_file.read.chomp if master_id_file.file?

          # If we have the ID and the VM exists already, then we
          # have nothing to do. Success!
          if env[:clone_id] && env[:machine].provider.driver.vm_exists?(env[:clone_id])
            @logger.info(
              "Master VM for '#{env[:machine].box.name}' already exists " +
              " (id=#{env[:clone_id]}) - skipping import step.")
            return
          else
            if env.delete(:clone_id)
              @logger.info("Deleting previous reference for master VM" +
                "'#{env[:machine].box.name}' (id=#{env[:clone_id]}) - " +
                "maybe it was removed manually")
            end
          end

          env[:ui].info(I18n.t("vagrant.actions.vm.clone.setup_master"))
          env[:ui].detail(I18n.t("vagrant.actions.vm.clone.setup_master_detail"))

          # Import the virtual machine
          import_env = env[:action_runner].run(Import, env.dup.merge(skip_machine: true))
          env[:clone_id] = import_env[:machine_id]

          @logger.info(
            "Imported box #{env[:machine].box.name} as master vm " +
            "with id #{env[:clone_id]}")

          @logger.debug("Writing id of master VM '#{env[:clone_id]}' to #{master_id_file}")
          master_id_file.open("w+") do |f|
            f.write(env[:clone_id])
          end
        end
      end
    end
  end
end
