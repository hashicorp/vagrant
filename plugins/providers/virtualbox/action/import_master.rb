require "log4r"
#require "lockfile"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ImportMaster
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::create_master")
        end

        def call(env)
          master_id_file = env[:machine].box.directory.join("master_id")
          
          env[:machine].env.lock(Digest::MD5.hexdigest(env[:machine].box.name), retry: true) do
            env[:master_id] = master_id_file.read.chomp if master_id_file.file?          
            if env[:master_id] && env[:machine].provider.driver.vm_exists?(env[:master_id])
              # Master VM already exists -> nothing to do - continue.
              @logger.info("Master VM for '#{env[:machine].box.name}' already exists (id=#{env[:master_id]}) - skipping import step.")
              return @app.call(env) 
            end          
            
            env[:ui].info I18n.t("vagrant.actions.vm.clone.importing", name: env[:machine].box.name)
            
            # Import the virtual machine
            ovf_file = env[:machine].box.directory.join("box.ovf").to_s
            env[:master_id] = env[:machine].provider.driver.import(ovf_file) do |progress|
              env[:ui].clear_line
              env[:ui].report_progress(progress, 100, false)
            end
            
            # Clear the line one last time since the progress meter doesn't disappear immediately.
            env[:ui].clear_line
            
            # Flag as erroneous and return if import failed
            raise Vagrant::Errors::VMImportFailure if !env[:master_id]

            @logger.info("Imported box #{env[:machine].box.name} as master vm with id #{env[:master_id]}")

            @logger.info("Creating base snapshot for master VM.")
            env[:machine].provider.driver.create_snapshot(env[:master_id], "base") do |progress|
              env[:ui].clear_line
              env[:ui].report_progress(progress, 100, false)
            end
              
            @logger.debug("Writing id of master VM '#{env[:master_id]}' to #{master_id_file}")
            master_id_file.open("w+") do |f|
              f.write(env[:master_id])
            end
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
      end
    end
  end
end
