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

          create_metadata

          @app.call(env)

          mount_shared_folders
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
          proc = lambda do |vm|
            @env.ui.info I18n.t("vagrant.actions.vm.share_folders.creating")

            shared_folders.each do |name, data|
              folder = VirtualBox::SharedFolder.new
              folder.name = name
              folder.host_path = File.expand_path(data[:hostpath], @env.env.root_path)
              vm.shared_folders << folder
            end
          end

          @env["vm.modify"].call(proc)
        end

        def mount_shared_folders
          @env.ui.info I18n.t("vagrant.actions.vm.share_folders.mounting")

          @env["vm"].ssh.execute do |ssh|
            # short guestpaths first, so we don't step on ourselves
            folders = shared_folders.sort_by do |name, data|
              if data[:guestpath]
                data[:guestpath].length
              else
                # A long enough path to just do this at the end.
                10000
              end
            end

            # Go through each folder and mount
            folders.each do |name, data|
              if data[:guestpath]
                # Guest path specified, so mount the folder to specified point
                @env.ui.info(I18n.t("vagrant.actions.vm.share_folders.mounting_entry",
                                    :name => name,
                                    :guest_path => data[:guestpath]))

                # Calculate the owner and group
                owner = data[:owner] || @env["config"].ssh.username
                group = data[:group] || @env["config"].ssh.username

                # Mount the actual folder
                @env["vm"].system.mount_shared_folder(ssh, name, data[:guestpath], owner, group)
              else
                # If no guest path is specified, then automounting is disabled
                @env.ui.info(I18n.t("vagrant.actions.vm.share_folders.nomount_entry",
                                    :name => name))
              end
            end
            ssh.exit
          end
        end
      end
    end
  end
end
