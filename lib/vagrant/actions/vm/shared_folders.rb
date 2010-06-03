module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          @runner.env.config.vm.shared_folders.inject([]) do |acc, data|
            name, value = data
            acc << [name, File.expand_path(value[:hostpath]), value[:guestpath], value[:rsyncpath]].compact
          end
        end

        def before_boot
          clear_shared_folders
          create_metadata
        end

        def after_boot
          logger.info "Mounting shared folders..."

          @runner.ssh.execute do |ssh|
            @runner.system.prepare_rsync(ssh) if @runner.env.config.vm.rsync_required

            shared_folders.each do |name, hostpath, guestpath, rsyncpath|
              logger.info "-- #{name}: #{rsyncpath ? guestpath + " -rsync-> " + rsyncpath : guestpath}"
              @runner.system.mount_shared_folder(ssh, name, guestpath)
              if rsyncpath
                @runner.system.create_rsync(ssh, :rsyncpath => rsyncpath, :guestpath => guestpath)
              end
            end
          end
        end

        def clear_shared_folders
          logger.info "Clearing previously set shared folders..."

          folders = @runner.vm.shared_folders.dup
          folders.each do |shared_folder|
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
