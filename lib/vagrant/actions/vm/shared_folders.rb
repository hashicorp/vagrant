module Vagrant
  module Actions
    module VM
      class SharedFolders < Base
        # This method returns an actual list of VirtualBox shared
        # folders to create and their proper path.
        def shared_folders
          runner.env.config.vm.shared_folders.inject({}) do |acc, data|
            key, value = data

            # This to prevent overwriting the actual shared folders data
            value = value.dup

            if value[:sync]
              # Syncing this folder. Change the guestpath to reflect
              # what we're actually mounting.
              value[:original] = value.dup
              value[:guestpath] = "#{value[:guestpath]}#{runner.env.config.unison.folder_suffix}"
            end

            acc[key] = value
            acc
          end
        end

        # This method returns the list of shared folders which are to
        # be synced via unison.
        def unison_folders
          shared_folders.inject({}) do |acc, data|
            key, value = data
            acc[key] = value if !!value[:sync]
            acc
          end
        end

        def before_boot
          clear_shared_folders
          create_metadata
        end

        def after_boot
          mount_shared_folders
          setup_unison
        end

        def mount_shared_folders
          logger.info "Mounting shared folders..."

          @runner.ssh.execute do |ssh|
            shared_folders.each do |name, data|
              logger.info "-- #{name}: #{data[:guestpath]}"
              @runner.system.mount_shared_folder(ssh, name, data[:guestpath])
            end
          end
        end

        def setup_unison
          return if unison_folders.empty?

          runner.ssh.execute do |ssh|
            runner.system.prepare_unison(ssh)

            logger.info "Creating unison crontab entries..."
            unison_folders.each do |name, data|
              runner.system.create_unison(ssh, data)
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

          shared_folders.each do |name, data|
            folder = VirtualBox::SharedFolder.new
            folder.name = name
            folder.host_path = File.expand_path(data[:hostpath], runner.env.root_path)
            @runner.vm.shared_folders << folder
          end

          @runner.vm.save
        end
      end
    end
  end
end
