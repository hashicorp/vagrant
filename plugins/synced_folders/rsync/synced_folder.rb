require 'log4r'

require 'vagrant/util/subprocess'
require 'vagrant/util/which'

require_relative 'helper'

module VagrantPlugins
  module SyncedFolderRSync
    class SyncedFolder < Vagrant.plugin('2', :synced_folder)
      include Vagrant::Util

      def initialize(*args)
        super

        @logger = Log4r::Logger.new('vagrant::synced_folders::rsync')
      end

      def usable?(_machine, raise_error = false)
        rsync_path = Which.which('rsync')
        return true if rsync_path
        return false unless raise_error
        fail Vagrant::Errors::RSyncNotFound
      end

      def prepare(_machine, _folders, _opts)
        # Nothing is necessary to do before VM boot.
      end

      def enable(machine, folders, _opts)
        if machine.guest.capability?(:rsync_installed)
          installed = machine.guest.capability(:rsync_installed)
          unless installed
            can_install = machine.guest.capability?(:rsync_install)
            fail Vagrant::Errors::RSyncNotInstalledInGuest unless can_install
            machine.ui.info I18n.t('vagrant.rsync_installing')
            machine.guest.capability(:rsync_install)
          end
        end

        ssh_info = machine.ssh_info

        if ssh_info[:private_key_path].empty? && ssh_info[:password]
          machine.ui.warn(I18n.t('vagrant.rsync_ssh_password'))
        end

        folders.each do |_id, folder_opts|
          RsyncHelper.rsync_single(machine, ssh_info, folder_opts)
        end
      end
    end
  end
end
