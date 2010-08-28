module Vagrant
  class Action
    module VM
      class ShareFolders
        include ExceptionCatcher

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          create_metadata

          @app.call(env)

          if !env.error?
            catch_action_exception(env) do
              # Only mount and setup shared folders in the absense of an
              # error
              mount_shared_folders
            end
          end
        end

        # This method returns an actual list of VirtualBox shared
        # folders to create and their proper path.
        def shared_folders
          @env.env.config.vm.shared_folders.inject({}) do |acc, data|
            key, value = data

            next acc if value[:disabled]

            # This to prevent overwriting the actual shared folders data
            value = value.dup
            acc[key] = value
            acc
          end
        end

        def create_metadata
          @env.ui.info "vagrant.actions.vm.share_folders.creating"

          shared_folders.each do |name, data|
            folder = VirtualBox::SharedFolder.new
            folder.name = name
            folder.host_path = File.expand_path(data[:hostpath], @env.env.root_path)
            @env["vm"].vm.shared_folders << folder
          end

          @env["vm"].vm.save
        end

        def mount_shared_folders
          @env.ui.info "vagrant.actions.vm.share_folders.mounting"

          @env["vm"].ssh.execute do |ssh|
            shared_folders.each do |name, data|
              @env.ui.info("vagrant.actions.vm.share_folders.mounting_entry",
                           :name => name,
                           :guest_path => data[:guestpath])
              @env["vm"].system.mount_shared_folder(ssh, name, data[:guestpath])
            end
          end
        end
      end
    end
  end
end
