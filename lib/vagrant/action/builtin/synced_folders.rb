require "log4r"

require 'vagrant/util/platform'

require_relative "mixin_synced_folders"

module Vagrant
  module Action
    module Builtin
      # This middleware will setup the synced folders for the machine using
      # the appropriate synced folder plugin.
      class SyncedFolders
        include MixinSyncedFolders

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::synced_folders")
        end

        def call(env)
          folders = synced_folders(env[:machine])

          folders.each do |impl_name, fs|
            @logger.info("Synced Folder Implementation: #{impl_name}")

            fs.each do |id, data|
              # Log every implementation and their paths
              @logger.info("  - #{id}: #{data[:hostpath]} => #{data[:guestpath]}")
            end
          end

          # Go through each folder and make sure to create it if
          # it does not exist on host
          folders.each do |_, fs|
            fs.each do |id, data|
              data[:hostpath] = File.expand_path(data[:hostpath], env[:root_path])

              # Create the hostpath if it doesn't exist and we've been told to
              if !File.directory?(data[:hostpath]) && data[:create]
                @logger.info("Creating shared folder host directory: #{data[:hostpath]}")
                begin
                  Pathname.new(data[:hostpath]).mkpath
                rescue Errno::EACCES
                  raise Vagrant::Errors::SharedFolderCreateFailed,
                    path: data[:hostpath]
                end
              end

              if File.directory?(data[:hostpath])
                data[:hostpath] = File.realpath(data[:hostpath])
                data[:hostpath] = Util::Platform.fs_real_path(data[:hostpath]).to_s
              end
            end
          end

          # Go through each folder and prepare the folders
          folders.each do |impl_name, fs|
            @logger.info("Invoking synced folder prepare for: #{impl_name}")
            plugins[impl_name.to_sym][0].new.prepare(env[:machine], fs, impl_opts(impl_name, env))
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # Once booted, setup the folder contents
          folders.each do |impl_name, fs|
            @logger.info("Invoking synced folder enable: #{impl_name}")
            plugins[impl_name.to_sym][0].new.enable(env[:machine], fs, impl_opts(impl_name, env))
          end
        end
      end
    end
  end
end
