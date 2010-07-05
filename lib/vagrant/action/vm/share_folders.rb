module Vagrant
  class Action
    module VM
      class ShareFolders
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          clear_shared_folders
          create_metadata

          @app.call(env)

          if !env.error?
            # Only mount and setup shared folders in the absense of an
            # error
            mount_shared_folders
            setup_unison
          end
        end

        # This method returns an actual list of VirtualBox shared
        # folders to create and their proper path.
        def shared_folders
          @env.env.config.vm.shared_folders.inject({}) do |acc, data|
            key, value = data

            # This to prevent overwriting the actual shared folders data
            value = value.dup

            if value[:sync]
              # Syncing this folder. Change the guestpath to reflect
              # what we're actually mounting.
              value[:original] = value.dup
              value[:guestpath] = "#{value[:guestpath]}#{@env.env.config.unison.folder_suffix}"
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

        def clear_shared_folders
          if @env["vm"].vm.shared_folders.length > 0
            @env.logger.info "Clearing previously set shared folders..."

            folders = @env["vm"].vm.shared_folders.dup
            folders.each do |shared_folder|
              shared_folder.destroy
            end

            @env["vm"].reload!
          end
        end

        def create_metadata
          @env.logger.info "Creating shared folders metadata..."

          shared_folders.each do |name, data|
            folder = VirtualBox::SharedFolder.new
            folder.name = name
            folder.host_path = File.expand_path(data[:hostpath], @env.env.root_path)
            @env["vm"].vm.shared_folders << folder
          end

          @env["vm"].vm.save
        end

        def mount_shared_folders
          @env.logger.info "Mounting shared folders..."

          @env["vm"].ssh.execute do |ssh|
            shared_folders.each do |name, data|
              @env.logger.info "-- #{name}: #{data[:guestpath]}"
              @env["vm"].system.mount_shared_folder(ssh, name, data[:guestpath])
            end
          end
        end

        def setup_unison
          return if unison_folders.empty?

          @env["vm"].ssh.execute do |ssh|
            @env["vm"].system.prepare_unison(ssh)

            @env.logger.info "Creating unison crontab entries..."
            unison_folders.each do |name, data|
              @env["vm"].system.create_unison(ssh, data)
            end
          end
        end
      end
    end
  end
end
