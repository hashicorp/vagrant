require 'pathname'

require 'log4r'

module Vagrant
  module Action
    module VM
      class ShareFolders
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::share_folders")
          @app    = app
        end

        def call(env)
          @env = env

          prepare_folders
          create_metadata

          @app.call(env)

          mount_shared_folders
        end

        # This method returns an actual list of VirtualBox shared
        # folders to create and their proper path.
        def shared_folders
          @env[:vm].config.vm.shared_folders.inject({}) do |acc, data|
            key, value = data

            next acc if value[:disabled]

            # This to prevent overwriting the actual shared folders data
            value = value.dup
            acc[key] = value
            acc
          end
        end

        # Prepares the shared folders by verifying they exist and creating them
        # if they don't.
        def prepare_folders
          shared_folders.each do |name, options|
            hostpath = Pathname.new(options[:hostpath]).expand_path(@env[:root_path])

            if !hostpath.directory? && options[:create]
              # Host path doesn't exist, so let's create it.
              @logger.debug("Host path doesn't exist, creating: #{hostpath}")

              begin
                hostpath.mkpath
              rescue Errno::EACCES
                raise Errors::SharedFolderCreateFailed, :path => hostpath.to_s
              end
            end
          end
        end

        def create_metadata
          @env[:ui].info I18n.t("vagrant.actions.vm.share_folders.creating")

          folders = []
          shared_folders.each do |name, data|
            folders << {
              :name => name,
              :hostpath => File.expand_path(data[:hostpath], @env[:root_path])
            }
          end

          @env[:vm].driver.share_folders(folders)
        end

        def mount_shared_folders
          @env[:ui].info I18n.t("vagrant.actions.vm.share_folders.mounting")

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
              @env[:ui].info(I18n.t("vagrant.actions.vm.share_folders.mounting_entry",
                                    :name => name,
                                    :guest_path => data[:guestpath]))

              # Dup the data so we can pass it to the guest API
              data = data.dup

              # Calculate the owner and group
              data[:owner] ||= @env[:vm].config.ssh.username
              data[:group] ||= @env[:vm].config.ssh.username

              # Mount the actual folder
              @env[:vm].guest.mount_shared_folder(name, data[:guestpath], data)
            else
              # If no guest path is specified, then automounting is disabled
              @env[:ui].info(I18n.t("vagrant.actions.vm.share_folders.nomount_entry",
                                    :name => name))
            end
          end
        end
      end
    end
  end
end
