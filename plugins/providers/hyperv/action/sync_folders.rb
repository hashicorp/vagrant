#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require "debugger"
require "log4r"
require "vagrant/util/subprocess"
require "vagrant/util/which"

module VagrantPlugins
  module HyperV
    module Action
      class SyncFolders

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_hyperv::action::sync_folders")
        end

        def call(env)
          @env = env
          @app.call(env)
          if env[:machine].config.vm.guest == :windows
            sync_folders_to_windows
          elsif env[:machine].config.vm.guest == :linux
            sync_folders_to_linux
          end
        end

        def ssh_info
          @ssh_info ||= @env[:machine].ssh_info
        end

        def sync_folders_to_windows
          @env[:machine].config.vm.synced_folders.each do |id, data|
            # Ignore disabled shared folders
            next if data[:disabled] || data[:smb]
            hostpath  = File.expand_path(data[:hostpath], @env[:root_path]).gsub("/", "\\")
            guestpath = data[:guestpath].gsub("/", "\\")
            options = { :guest_ip => ssh_info[:host],
                        :username => ssh_info[:username],
                        :host_path => hostpath,
                        :guest_path => guestpath,
                        :vm_id => @env[:machine].id,
                        :password => @env[:machine].provider_config.guest.password }
            response = @env[:machine].provider.driver.execute('file_sync.ps1', options)
            end
        end

        def sync_folders_to_linux
          if ssh_info.nil?
            @env[:ui].info('SSH Info not available, Aborting Sync folder')
            return
          end

          @env[:machine].config.vm.synced_folders.each do |id, data|
            # Ignore disabled shared folders
            next if data[:disabled] || data[:smb]
            hostpath  = File.expand_path(data[:hostpath], @env[:root_path])
            guestpath = data[:guestpath]
            @env[:ui].info('Starting Sync folders')
            begin
              @env[:machine].communicate.upload(hostpath, guestpath)
            rescue RuntimeError => e
              @env[:ui].error(e.message)
            end

          end
        end

      end
    end
  end
end
