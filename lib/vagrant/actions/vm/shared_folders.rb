module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          @runner.env.config.vm.shared_folders.inject([]) do |acc, data|
            name, value = data
            acc << [name, File.expand_path(value[:hostpath], @runner.env.root_path), value[:guestpath], value[:syncpath]].compact
          end
        end

        def before_boot
          clear_shared_folders
          create_metadata
        end

        def after_boot
          logger.info "Mounting shared folders..."

          @runner.ssh.execute do |ssh|
            @runner.system.prepare_sync(ssh) if @runner.env.config.vm.sync_required

            shared_folders.each do |name, hostpath, guestpath, syncpath|
              logger.info "-- #{name}: #{syncpath ? guestpath + " -sync-> " + syncpath : guestpath}"
              @runner.system.mount_shared_folder(ssh, name, guestpath)
              if syncpath
                @runner.system.create_sync(ssh, :syncpath => syncpath, :guestpath => guestpath)
              end
            end
          end
        end

        def clear_shared_folders
          if runner.vm.shared_folders.length > 0
            logger.info "Clearing previously set shared folders..."

            folders = @runner.vm.shared_folders.dup
            folders.each do |shared_folder|
              shared_folder.destroy
            end

            @runner.reload!
          end
        end

        def create_metadata
          logger.info "Creating shared folders metadata..."

          shared_folders.each do |name, hostpath, guestpath|
            folder = VirtualBox::SharedFolder.new
            folder.name = name
            folder.host_path = hostpath
            @runner.vm.shared_folders << folder
          end

          @runner.vm.save
        end
      end
    end
  end
end
