require "log4r"

require "vagrant/util/subprocess"
require "vagrant/util/which"

require_relative "helper"

module VagrantPlugins
  module SyncedFolderWinRM
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      include Vagrant::Util

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::synced_folders::winrm")
      end

      def usable?(machine, raise_error=false)
        true if machine.config.vm.communicator == :winrm
      end

      def prepare(machine, folders, opts)
        # Nothing is necessary to do before VM boot.
      end

      def enable(machine, folders, opts)
        winrm_info = VagrantPlugins::CommunicatorWinRM::Helper.winrm_info(machine)

        folders.each do |id, folder_opts|
          WinRMHelper.winrm_single(machine, winrm_info, folder_opts)
        end
      end
    end
  end
end
