module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          @runner.env.config.vm.shared_folders.inject([]) do |acc, data|
            name, value = data
            acc << [name, File.expand_path(value[:hostpath]), value[:guestpath]]
          end
        end

        def before_boot
          clear_shared_folders
          create_metadata
        end

        def after_boot
          logger.info "Mounting shared folders..."

          @runner.env.ssh.execute do |ssh|
            shared_folders.each do |name, hostpath, guestpath|
              logger.info "-- #{name}: #{guestpath}"
              @runner.system.mount_shared_folder(ssh, name, guestpath)
            end
          end
        end

        def clear_shared_folders
          logger.info "Clearing previously set shared folders..."

          @runner.vm.shared_folders.each do |shared_folder|
            shared_folder.destroy
          end

          @runner.reload!
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