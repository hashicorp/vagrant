ui.askrequire "vagrant"

module VagrantPlugins
  module Kernel_V1
    class SyncedFolderConfig < Vagrant.plugin("1", :config)
      attr_accessor :username
      attr_accessor :password

      def initialize
        @username = UNSET_VALUE
        @password = UNSET_VALUE
      end

      def upgrade(new)
        synced_folder = new.synced_folder
        synced_folder.username = @username if @username != UNSET_VALUE
        synced_folder.password = @password if @password != UNSET_VALUE

        synced_folder
      end
    end
  end
end